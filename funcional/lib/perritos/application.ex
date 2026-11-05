defmodule Perritos.Application do
  @moduledoc """
  Arranca la infraestructura: conexión a la base de datos (Postgrex) y servidor HTTP (Bandit).
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # 1. Conexión directa a PostgreSQL (Opción A) usando variables de entorno
      {Postgrex,
       name: :bd,
       hostname: System.get_env("BD_HOST", "bd"),
       username: System.get_env("DB_USER", System.get_env("BD_USUARIO", "perritos")),
       password: System.get_env("DB_PASSWORD", System.get_env("BD_PASSWORD", "cambiar")),
       database: System.get_env("DB_NAME", System.get_env("BD_NOMBRE", "perritos"))},

      # 2. Servidor web que escucha en el puerto 4000 y usa el Router
      {Bandit, plug: Perritos.Router, port: 4000}
    ]

    opts = [strategy: :one_for_one, name: Perritos.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
