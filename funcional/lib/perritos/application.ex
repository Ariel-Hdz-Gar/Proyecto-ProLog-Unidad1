defmodule Perritos.Application do
  @moduledoc """
  Arranca la infraestructura: conexión a la base de datos (Postgrex) y servidor HTTP (Bandit).
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Postgrex,
       name: :bd,
       hostname: System.get_env("BD_HOST", "bd"),
       username: System.get_env("BD_USUARIO", "perritos"),
       password: System.get_env("BD_PASSWORD", "cambiar"),
       database: System.get_env("BD_NOMBRE", "perritos")},
      {Bandit, plug: Perritos.Router, port: 4000}
    ]

    opts = [strategy: :one_for_one, name: Perritos.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
