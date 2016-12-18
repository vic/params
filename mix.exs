defmodule Params.Mixfile do
  use Mix.Project

  def project do
    [app: :params,
     version: "2.0.2",
     elixir: "~> 1.2",
     name: "Params",
     source_url: github(),
     homepage_url: "https://hex.pm/packages/params",
     docs: docs(),
     description: description(),
     package: package(),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def description do
  """
  Parameter structure validation and casting with Ecto.Schema.
 """
  end

  def github do
    "https://github.com/vic/params"
  end

  def package do
    [files: ~w(lib mix.exs README* LICENSE),
     maintainers: ["Victor Hugo Borja <vborja@apache.org>"],
     licenses: ["Apache 2.0"],
     links: %{
       "GitHub" => github()
     }]
  end

  def docs do
    [
      extras: ["README.md"]
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
     {:ecto, "~> 2.0"},
     {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
     {:earmark, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
