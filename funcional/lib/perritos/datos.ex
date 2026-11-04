defmodule Perritos.Datos do
  @moduledoc """
  Cáscara: lee los avistamientos directamente de la base de datos PostgreSQL (Opción A).
  """

  # Consulta pura sin concatenaciones raras para evitar inyecciones SQL
  @consulta "SELECT latitud, longitud FROM perritos WHERE latitud IS NOT NULL AND longitud IS NOT NULL"

  def avistamientos do
    # :bd es el nombre de la conexión que configuraremos en el supervisor
    case Postgrex.query(:bd, @consulta, []) do
      {:ok, %Postgrex.Result{rows: filas}} ->
        # Convertimos la respuesta de PostgreSQL en la lista de mapas que tu núcleo puro espera
        {:ok, Enum.map(filas, fn [lat, lon] ->
          %{
            lat: convertir_a_flotante(lat),
            lon: convertir_a_flotante(lon)
          }
        end)}

      {:error, error} ->
        {:error, error}
    end
  end

  # PostgreSQL manda los campos numéricos como %Decimal{}, debemos pasarlos a flotante
  defp convertir_a_flotante(%Decimal{} = num), do: Decimal.to_float(num)
  defp convertir_a_flotante(num) when is_float(num), do: num
  defp convertir_a_flotante(num) when is_integer(num), do: num / 1
  defp convertir_a_flotante(_), do: nil
end