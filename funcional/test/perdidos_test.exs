defmodule Perritos.PerdidosTest do
  use ExUnit.Case, async: true
  doctest Perritos.Perdidos

  alias Perritos.Perdidos

  @ahora ~N[2026-11-04 12:00:00]

  # Estructura auxiliar simulada para las pruebas del núcleo
  defp perro(id, nombre, fecha) do
    %{id: id, nombre: nombre, fecha: fecha}
  end

  test "lista vacía regresa lista vacía" do
    assert Perdidos.filtrar_perdidos([], 7, @ahora) == []
  end

  test "filtra correctamente perros que superan el límite de días" do
    perro_reiente = perro(1, "Firulais", ~N[2026-11-02 10:00:00]) # Hace 2 días
    perro_antiguo = perro(2, "Solovino", ~N[2026-10-20 10:00:00]) # Hace 15 días

    resultado = Perdidos.filtrar_perdidos([perro_reiente, perro_antiguo], 7, @ahora)

    assert resultado == [perro_antiguo]
  end

  test "ordena del más antiguo al más reciente" do
    p1 = perro(1, "PerroA", ~N[2026-09-01 10:00:00])
    p2 = perro(2, "PerroB", ~N[2026-10-01 10:00:00])

    resultado = Perdidos.filtrar_perdidos([p1, p2], 7, @ahora)

    assert Enum.map(resultado, & &1.id) == [1, 2]
  end

  test "calcula correctamente los días transcurridos" do
    fecha_avistamiento = ~N[2026-10-25 15:30:00]
    assert Perdidos.dias_transcurridos(fecha_avistamiento, @ahora) == 10
  end
  test "caso borde: límite exacto de días" do
    # Exactamente 7 días antes
    perro_exacto = perro(3, "Pulgoso", ~N[2026-10-28 12:00:00])

    resultado = Perdidos.filtrar_perdidos([perro_exacto], 7, @ahora)

    assert length(resultado) == 1
  end
end