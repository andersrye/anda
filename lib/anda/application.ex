defmodule Anda.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AndaWeb.Telemetry,
      Anda.Repo,
      {DNSCluster, query: Application.get_env(:anda, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Anda.PubSub},
      # Start the Finch HTTP client for sending emails
      #{Finch, name: Anda.Finch},
      # Start a worker by calling: Anda.Worker.start_link(arg)
      # {Anda.Worker, arg},
      # Start to serve requests, typically the last entry
      AndaWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Anda.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AndaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
