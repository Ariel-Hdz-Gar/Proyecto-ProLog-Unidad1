defmodule Perritos.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # 1. Conexión directa a PostgreSQL (Opción A) usando variables de entorno[cite: 16]
      {Postgrex, 
        name: :bd, 
        hostname: System.fetch_env!("BD_HOST"),
        username: System.fetch_env!("DB_USER"),
        password: System.fetch_env!("DB_PASSWORD"),
        database: System.fetch_env!("DB_NAME")},
        
      # 2. Servidor web que escucha en el puerto 4000 y usa tu Router[cite: 16, 20]
      {Bandit, plug: Perritos.Router, port: 4000}
    ]

    opts = [strategy: :one_for_one, name: Perritos.Supervisor]
    Supervisor.start_link(children, opts)
  end
end