defmodule Perritos.Perdidos do
  @moduledoc """
  Núcleo de la funcionalidad *Perros perdidos de vista*.
  Filtra, ordena y calcula los días exactos de los avistamientos que no se han reportado en N días.
  """

  @doc """
  Calcula los días transcurridos desde la fecha del avistamiento hasta hoy.
  
  iex> Perritos.Perdidos.dias_transcurridos(~N[2026-10-01 10:00:00], ~N[2026-10-10 10:00:00])
  9
  """
  def dias_transcurridos(%NaiveDateTime{} = fecha_avistamiento, %NaiveDateTime{} = ahora) do
    ahora
    |> NaiveDateTime.to_date()
    |> Date.diff(NaiveDateTime.to_date(fecha_avistamiento))
  end

  @doc """
  Filtra los perritos cuyo último avistamiento sea mayor o igual al `dias_limite`.
  Inyecta el campo `:dias_exactos` para ser consumido por el Front-End.
  Recibe una lista de avistamientos, el límite de días y la fecha actual (inyectada para mantener la pureza).
  """
  def filtrar_perdidos(avistamientos, dias_limite \\ 7, ahora) do
    avistamientos
    |> Enum.filter(fn a -> dias_transcurridos(a.fecha, ahora) >= dias_limite end)
    |> Enum.map(fn a ->
      dias = dias_transcurridos(a.fecha, ahora)
      
      # Convertimos a mapa regular (si es un struct de Ecto u otro) para permitir nuevas llaves
      registro = if is_struct(a), do: Map.from_struct(a), else: a
      
      Map.put(registro, :dias_exactos, dias)
    end)
    |> Enum.sort_by(&Map.get(&1, :fecha), {:asc, NaiveDateTime})
  end
end