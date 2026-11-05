defmodule Perritos.Router do
  @moduledoc """
  Cáscara HTTP: traduce peticiones HTTP en llamadas a los núcleos funcionales y responde en JSON.
  """

  use Plug.Router
  plug :match
  plug :dispatch

  # Ruta de comprobación de salud exigida por el profesor
  get "/f/salud" do
    send_resp(conn, 200, "ok")
  end

  # Funcionalidad 4 (Ariel Hernández): Zonas de Concentración
  get "/f/zonas" do
    case Perritos.Datos.coordenadas() do
      {:ok, avistamientos} ->
        resultado = Perritos.Zonas.calcular_zonas(avistamientos)

        formato_json =
          Enum.map(resultado, fn {{lat, lon}, total} ->
            %{latitud: lat, longitud: lon, total_perritos: total}
          end)

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(formato_json))

      {:error, _} ->
        send_resp(conn, 503, ~s({"error": "base de datos no disponible"}))
    end
  end

  # Funcionalidad 3 (Santiago Martínez): Estadísticas Generales
  get "/f/estadisticas" do
    case Perritos.Datos.avistamientos() do
      {:ok, avistamientos} ->
        cuerpo =
          avistamientos
          |> Perritos.Estadisticas.resumen()
          |> Jason.encode!()

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, cuerpo)

      {:error, _motivo} ->
        send_resp(conn, 503, ~s({"error": "base de datos no disponible"}))
    end
  end

  match _ do
    send_resp(conn, 404, "no encontrado")
  end
end
