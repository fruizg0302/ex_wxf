defmodule ExWxf.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_wxf,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.html": :test,
        quality: :test
      ],
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        plt_add_apps: [:credo],
        ignore_warnings: ".dialyzer_ignore.exs",
        list_unused_filters: true,
        flags: [
          :unmatched_returns,
          :error_handling,
          :underspecs,
          :extra_return,
          :missing_return
        ]
      ],
      description: "Elixir encoder/decoder for the Wolfram eXchange Format (WXF)",
      package: package(),
      source_url: "https://github.com/fruizg0302/ex_wxf"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.13", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      {:stream_data, "~> 1.0", only: :test}
    ]
  end

  defp aliases do
    [
      precommit: [
        "compile --warnings-as-errors",
        "deps.unlock --unused",
        "format",
        "credo --strict",
        "test"
      ],
      quality: [
        "compile --warnings-as-errors",
        "deps.unlock --check-unused",
        "format --check-formatted",
        "credo --strict",
        "sobelow --config",
        "cmd mix hex.audit",
        "dialyzer",
        "cmd MIX_ENV=test mix coveralls"
      ]
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/fruizg0302/ex_wxf"}
    ]
  end
end
