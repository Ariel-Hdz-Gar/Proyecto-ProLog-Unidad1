defmodule Perritos.Router do
  use Plug.Router
  plug :match
  plug :dispatch

  get "/f/zonas" do
    case Perritos.Datos.avistamientos() do
      {:ok, avistamientos} ->
        # 1. El núcleo hace el cálculo puro
        resultado = Perritos.Zonas.calcular_zonas(avistamientos)
        
        # 2. La cáscara adapta las tuplas para que Jason pueda codificarlas en JSON[cite: 20]
        formato_json = Enum.map(resultado, fn {{lat, lon}, total} -> 
          %{latitud: lat, longitud: lon, total_perritos: total} 
        end)

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(formato_json))

      {:error, _} ->
        send_resp(conn, 503, ~s({"error": "base de datos no disponible"}))
    end
  end

  match _ do
    send_resp(conn, 404, "no encontrado")
  end
end