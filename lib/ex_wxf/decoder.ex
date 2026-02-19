defmodule ExWxf.Decoder do
  @moduledoc "Decodes WXF binary expression data into Elixir terms."

  alias ExWxf.Expression
  alias ExWxf.Varint

  @spec decode_expression(binary(), keyword()) :: {term(), binary()}
  def decode_expression(binary, opts \\ []) when is_binary(binary) do
    raw = Keyword.get(opts, :raw, false)
    {result, rest} = decode_raw(binary)

    result = if raw, do: result, else: auto_map(result)
    {result, rest}
  end

  # --- Raw decoding (always returns Expression structs for symbols/functions/associations) ---

  @spec decode_raw(binary()) :: {term(), binary()}
  def decode_raw(<<token, rest::binary>>) do
    decode_token(token, rest)
  end

  def decode_raw(<<>>) do
    raise ExWxf.DecodeError, message: "unexpected end of input"
  end

  defp decode_token(0x43, <<>>), do: raise_truncated("Integer8", 1)
  defp decode_token(0x6A, rest) when byte_size(rest) < 2, do: raise_truncated("Integer16", 2)
  defp decode_token(0x69, rest) when byte_size(rest) < 4, do: raise_truncated("Integer32", 4)
  defp decode_token(0x4C, rest) when byte_size(rest) < 8, do: raise_truncated("Integer64", 8)
  defp decode_token(0x72, rest) when byte_size(rest) < 8, do: raise_truncated("Real64", 8)

  defp decode_token(0x43, <<value::8-little-signed, rest::binary>>), do: {value, rest}
  defp decode_token(0x6A, <<value::16-little-signed, rest::binary>>), do: {value, rest}
  defp decode_token(0x69, <<value::32-little-signed, rest::binary>>), do: {value, rest}
  defp decode_token(0x4C, <<value::64-little-signed, rest::binary>>), do: {value, rest}
  defp decode_token(0x72, <<value::64-little-float, rest::binary>>), do: {value, rest}

  defp decode_token(0x49, rest) do
    {len, rest} = Varint.decode(rest)
    <<digits::binary-size(len), rest::binary>> = rest
    {String.to_integer(digits), rest}
  end

  defp decode_token(0x53, rest) do
    {len, rest} = Varint.decode(rest)
    <<str::binary-size(len), rest::binary>> = rest
    {str, rest}
  end

  defp decode_token(0x42, rest) do
    {len, rest} = Varint.decode(rest)
    <<data::binary-size(len), rest::binary>> = rest
    {%Expression.BinaryString{data: data}, rest}
  end

  defp decode_token(0x73, rest) do
    {len, rest} = Varint.decode(rest)
    <<name::binary-size(len), rest::binary>> = rest
    {%Expression.Symbol{name: name}, rest}
  end

  defp decode_token(0x52, rest) do
    {len, rest} = Varint.decode(rest)
    <<value::binary-size(len), rest::binary>> = rest
    {%Expression.BigReal{value: value}, rest}
  end

  defp decode_token(0x66, rest) do
    {num_parts, rest} = Varint.decode(rest)
    {head, rest} = decode_raw(rest)
    {parts, rest} = decode_n_raw(num_parts, rest)
    {%Expression.Function{head: head, parts: parts}, rest}
  end

  defp decode_token(0x41, rest) do
    {num_rules, rest} = Varint.decode(rest)
    {rules, rest} = decode_n_rules(num_rules, rest)
    {%Expression.Association{rules: rules}, rest}
  end

  defp decode_token(0x2D, rest) do
    {key, rest} = decode_raw(rest)
    {value, rest} = decode_raw(rest)
    {%Expression.Rule{key: key, value: value, delayed: false}, rest}
  end

  defp decode_token(0x3A, rest) do
    {key, rest} = decode_raw(rest)
    {value, rest} = decode_raw(rest)
    {%Expression.Rule{key: key, value: value, delayed: true}, rest}
  end

  defp decode_token(0xC1, <<type_byte, rest::binary>>) do
    decode_array(Expression.PackedArray, type_byte, rest)
  end

  defp decode_token(0xC2, <<type_byte, rest::binary>>) do
    decode_array(Expression.NumericArray, type_byte, rest)
  end

  defp decode_token(token, rest) do
    raise ExWxf.DecodeError,
      message: "unknown WXF token: 0x#{Integer.to_string(token, 16)}",
      binary: <<token>> <> rest
  end

  # --- Helpers ---

  defp decode_n_raw(0, rest), do: {[], rest}

  defp decode_n_raw(n, rest) do
    {expr, rest} = decode_raw(rest)
    {exprs, rest} = decode_n_raw(n - 1, rest)
    {[expr | exprs], rest}
  end

  defp decode_n_rules(0, rest), do: {[], rest}

  defp decode_n_rules(n, rest) do
    {rule, rest} = decode_raw(rest)
    {rules, rest} = decode_n_rules(n - 1, rest)
    {[rule | rules], rest}
  end

  defp decode_array(struct_module, type_byte, rest) do
    type = ExWxf.ArrayTypes.from_byte(type_byte)
    {rank, rest} = Varint.decode(rest)
    {dimensions, rest} = decode_n_varints(rank, rest)
    elem_size = ExWxf.ArrayTypes.element_size(type)
    total_elements = Enum.reduce(dimensions, 1, &(&1 * &2))
    data_size = total_elements * elem_size
    <<data::binary-size(data_size), rest::binary>> = rest
    {struct!(struct_module, type: type, dimensions: dimensions, data: data), rest}
  end

  defp decode_n_varints(0, rest), do: {[], rest}

  defp decode_n_varints(n, rest) do
    {val, rest} = Varint.decode(rest)
    {vals, rest} = decode_n_varints(n - 1, rest)
    {[val | vals], rest}
  end

  @spec raise_truncated(String.t(), pos_integer()) :: no_return()
  defp raise_truncated(type_name, expected_bytes) do
    raise ExWxf.DecodeError,
      message: "truncated #{type_name}: expected #{expected_bytes} bytes"
  end

  # --- Auto-mapping (raw Expression structs -> Elixir-native types) ---

  defp auto_map(%Expression.Symbol{name: "True"}), do: true
  defp auto_map(%Expression.Symbol{name: "False"}), do: false
  defp auto_map(%Expression.Symbol{name: "Null"}), do: nil
  defp auto_map(%Expression.Symbol{} = sym), do: sym

  defp auto_map(%Expression.Function{head: %Expression.Symbol{name: "List"}, parts: parts}) do
    Enum.map(parts, &auto_map/1)
  end

  defp auto_map(%Expression.Function{head: head, parts: parts}) do
    %Expression.Function{head: auto_map(head), parts: Enum.map(parts, &auto_map/1)}
  end

  defp auto_map(%Expression.Association{rules: rules}) do
    Map.new(rules, fn %Expression.Rule{key: key, value: value} ->
      {auto_map(key), auto_map(value)}
    end)
  end

  defp auto_map(%Expression.BigReal{} = br), do: br
  defp auto_map(%Expression.BinaryString{} = bs), do: bs
  defp auto_map(%Expression.PackedArray{} = pa), do: pa
  defp auto_map(%Expression.NumericArray{} = na), do: na

  defp auto_map(value) when is_integer(value), do: value
  defp auto_map(value) when is_float(value), do: value
  defp auto_map(value) when is_binary(value), do: value
end
