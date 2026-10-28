defmodule Perritos.MixProject do
  use Mix.Project

  def project do
    [
      app: :funcional,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      aliases: [test: "test --no-start"],
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Perritos.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug, "~> 1.16"},
      {:bandit, "~> 1.5"},
      {:jason, "~> 1.4"},
      {:postgrex, "~> 0.19"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end
end
