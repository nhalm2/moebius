defmodule Moebius.Mixfile do
  use Mix.Project

  @version "3.0.1"

  def project do
    [
      app: :moebius,
      description: "A functional approach to data access with Elixir",
      version: @version,
      elixir: "~> 1.6",
      package: package(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      # ExDoc
      name: "Moebius",
      docs: [
        source_ref: "v#{@version}",
        main: Moebius.Query,
        source_url: "https://github.com/nhalm2/moebius",
        extras: ["README.md"]
      ],
      deps: deps()
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      applications: [:logger, :postgrex]
    ]
  end

  defp deps do
    [
      {:postgrex, "~> 0.13.5"},
      {:inflex, "~> 1.10.0"},
      {:poolboy, "> 1.5.0"},
      {:poison, "~> 4.0"},
      {:ex_doc, "~> 0.19", only: [:dev, :docs]}
    ]
  end

  def package do
    [
      maintainers: ["Nick Halm"],
      licenses: ["New BSD"],
      links: %{"GitHub" => "https://github.com/nhalm2/moebius"}
    ]
  end
end
