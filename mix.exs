defmodule Leeroy.Mixfile do
  use Mix.Project

  def project do
    [
      app: :leeroy,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Leeroy.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:slack, "~> 0.12.0"},
      {:giphy, "~> 0.1.1"},
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false}
    ]
  end
end
