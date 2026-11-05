defmodule Perritos.Perdidos do
  @moduledoc """
  Núcleo de la funcionalidad *Perros perdidos de vista*.
  Filtra y ordena los avistamientos que no se han reportado en N días.
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
  Recibe una lista de avistamientos, el límite de días y la fecha actual (inyectada para mantener la pureza).
  """
  def filtrar_perdidos(avistamientos, dias_limite \\ 7, ahora) do
    avistamientos
    |> Enum.filter(fn a -> dias_transcurridos(a.fecha, ahora) >= dias_limite end)
    |> Enum.sort_by(& &1.fecha, {:asc, NaiveDateTime})
  end
end