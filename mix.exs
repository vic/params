defmodule Params.Mixfile do
  use Mix.Project

  @source_url "https://github.com/vic/params"
  @version "2.3.0"

  def project do
    [
      app: :params,
      version: @version,
      elixir: "~> 1.2",
      name: "Params",
      deps: deps(),
      docs: docs(),
      package: package(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      dialyzer: [plt_add_apps: [:ecto]],
      xref: [exclude: [Ecto.Changeset]]
    ]
  end

  def package do
    [
      description: "Parameter structure validation and casting with Ecto.Schema.",
      files: ~w(lib mix.exs README.md LICENSE CHANGELOG.md),
      maintainers: ["Victor Hugo Borja <vborja@apache.org>"],
      licenses: ["Apache-2.0"],
      links: %{
        "Changelog" => "https://hexdocs.pm/params/changelog.html",
        "GitHub" => @source_url
      }
    ]
  end

  def docs do
    [
      extras: [
        "CHANGELOG.md": [],
        LICENSE: [title: "License"],
        "README.md": [title: "Overview"]
      ],
      main: "readme",
      homepage_url: "https://hex.pm/packages/params",
      source_url: @source_url,
      formatters: ["html"]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:ecto, "~> 2.0 or ~> 3.0"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:dialyxir, "~> 0.5", only: :dev, runtime: false}
    ]
  end
end
