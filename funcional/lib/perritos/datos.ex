defmodule Perritos.Datos do
  @moduledoc """
  Cáscara unificada: lee los registros de perritos para el núcleo de todo el equipo.
  """

  # Consultamos todos los campos necesarios tanto para coordenadas como para fechas
  @consulta """
  SELECT id_perrito, nombre, foto_ruta, latitud, longitud, fecha_registro 
  FROM perritos
  """

  def avistamientos do
    case Postgrex.query(:bd, @consulta, []) do
      {:ok, %Postgrex.Result{rows: filas}} ->
        lista = Enum.map(filas, &a_avistamiento/1)
        {:ok, lista}

      {:error, error} ->
        {:error, error}
    end
  end

  defp a_avistamiento([id, nombre, foto_ruta, latitud, longitud, fecha_registro]) do
    %{
      id: id,
      nombre: nombre,
      foto: foto_ruta,
      lat: convertir_a_flotante(latitud),
      lon: convertir_a_flotante(longitud),
      # Campo clave para tu funcionalidad de perros perdidos de vista
      fecha: parsear_fecha(fecha_registro)
    }
  end

  defp convertir_a_flotante(%Decimal{} = num), do: Decimal.to_float(num)
  defp convertir_a_flotante(num) when is_float(num), do: num
  defp convertir_a_flotante(num) when is_integer(num), do: num / 1
  defp convertir_a_flotante(_), do: nil

  defp parsear_fecha(%DateTime{} = dt), do: DateTime.to_naive(dt)
  defp parsear_fecha(%NaiveDateTime{} = dt), do: dt
  defp parsear_fecha(str) when is_binary(str) do
    case NaiveDateTime.from_iso8601(str) do
      {:ok, dt} -> dt
      _ -> NaiveDateTime.utc_now()
    end
  end
  defp parsear_fecha(_), do: NaiveDateTime.utc_now()
end