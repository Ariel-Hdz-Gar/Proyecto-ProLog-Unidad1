defmodule Perritos.Datos do
  @moduledoc """
  Cáscara: acceso a datos (PostgreSQL).
  Consulta la base de datos y transforma las filas SQL en structs y mapas para los núcleos puros.
  """

  alias Perritos.Avistamiento

  # Consulta con JOINs a los catálogos del Proyecto 1
  @consulta """
  SELECT
    p.id_perrito,
    p.nombre,
    r.nombre AS raza,
    c.nombre AS color_principal,
    p.latitud,
    p.longitud,
    p.foto_ruta,
    p.fecha_registro
  FROM perritos p
  LEFT JOIN razas r ON p.id_raza = r.id_raza
  JOIN colores c ON p.id_color_principal = c.id_color
  ORDER BY p.fecha_registro DESC;
  """

  @doc """
  Obtiene todos los avistamientos registrados en la base de datos como structs de `Avistamiento`.
  """
  def avistamientos do
    case Postgrex.query(:bd, @consulta, []) do
      {:ok, %Postgrex.Result{rows: filas}} ->
        {:ok, Enum.map(filas, &a_avistamiento/1)}

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Obtiene coordenadas de avistamientos para el módulo de Zonas de Concentración.
  """
  def coordenadas do
    case avistamientos() do
      {:ok, lista} ->
        {:ok, Enum.map(lista, fn a -> %{lat: a.lat, lon: a.lon} end)}

      {:error, err} ->
        {:error, err}
    end
  end

  defp a_avistamiento([id, nombre, raza, color_principal, lat, lon, foto, fecha]) do
    %Avistamiento{
      id: id,
      nombre: nombre,
      raza: raza,
      color_principal: color_principal,
      colores: [color_principal],
      lat: convertir_decimal(lat),
      lon: convertir_decimal(lon),
      foto: foto,
      fecha: convertir_fecha(fecha)
    }
  end

  defp convertir_decimal(%Decimal{} = d), do: Decimal.to_float(d)
  defp convertir_decimal(f) when is_float(f), do: f
  defp convertir_decimal(n) when is_integer(n), do: n / 1
  defp convertir_decimal(_), do: 0.0

  defp convertir_fecha(%DateTime{} = dt), do: DateTime.to_naive(dt)
  defp convertir_fecha(%NaiveDateTime{} = ndt), do: ndt
  defp convertir_fecha(_), do: NaiveDateTime.utc_now()
end
