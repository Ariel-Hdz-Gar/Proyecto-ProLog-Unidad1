defmodule Perritos.EstadisticasTest do
  use ExUnit.Case, async: true
  doctest Perritos.Estadisticas

  alias Perritos.{Avistamiento, Estadisticas}

  # Helper para construir perritos de prueba rápidamente
  defp build_perro(id, nombre, raza, color_principal, fecha) do
    %Avistamiento{
      id: id,
      nombre: nombre,
      raza: raza,
      color_principal: color_principal,
      colores: [color_principal],
      lat: 25.42,
      lon: -101.00,
      foto: "foto.jpg",
      fecha: fecha
    }
  end

  # ----------------------------------------------------------------------------
  # CASOS BORDE (Requisito de la rúbrica)
  # ----------------------------------------------------------------------------

  test "Caso Borde 1: Lista vacía regresa ceros y estructuras vacías" do
    assert Estadisticas.resumen([]) == %{
             total_avistamientos: 0,
             por_raza: %{},
             por_color: %{},
             por_dia: %{},
             top_razas: [],
             top_colores: []
           }

    assert Estadisticas.contar_por_raza([]) == %{}
    assert Estadisticas.contar_por_color([]) == %{}
    assert Estadisticas.contar_por_dia([]) == %{}
    assert Estadisticas.top_n(%{}, 3) == []
  end

  test "Caso Borde 2: Manejo de perros sin raza o con raza nil / vacía" do
    perros = [
      build_perro(1, "Solovino", nil, "Café", ~N[2026-10-20 10:00:00]),
      build_perro(2, "Callejero", "", "Negro", ~N[2026-10-20 11:00:00]),
      build_perro(3, "Firulais", "Pug", "Dorado", ~N[2026-10-20 12:00:00])
    ]

    resultado = Estadisticas.contar_por_raza(perros)

    assert resultado == %{
             "Sin raza definida" => 2,
             "Pug" => 1
           }
  end

  test "Caso Borde 3: top_n cuando se pide más elementos de los que existen (n > total)" do
    mapa = %{"Negro" => 5, "Blanco" => 3}
    # Pedimos 10 aunque solo haya 2
    resultado = Estadisticas.top_n(mapa, 10)
    assert resultado == [{"Negro", 5}, {"Blanco", 3}]
  end

  test "Caso Borde 4: top_n con n = 0 regresa lista vacía" do
    mapa = %{"Negro" => 5, "Blanco" => 3}
    assert Estadisticas.top_n(mapa, 0) == []
  end

  # ----------------------------------------------------------------------------
  # PRUEBAS DE FUNCIONALIDAD COMPLETA
  # ----------------------------------------------------------------------------

  test "Agrupación correcta por color y fechas distintas" do
    perros = [
      build_perro(1, "Oso", "Chihuahua", "Negro", ~N[2026-10-18 10:00:00]),
      build_perro(2, "Manchas", "Dálmata", "Blanco", ~N[2026-10-18 15:30:00]),
      build_perro(3, "Negrito", "Criollo", "Negro", ~N[2026-10-19 09:00:00]),
      build_perro(4, "Canelo", "Pastor", "Café", ~N[2026-10-19 14:00:00]),
      build_perro(5, "Peluche", "Chihuahua", "Negro", ~N[2026-10-19 20:00:00])
    ]

    resumen = Estadisticas.resumen(perros)

    assert resumen.total_avistamientos == 5
    assert resumen.por_color == %{"Negro" => 3, "Blanco" => 1, "Café" => 1}
    assert resumen.por_dia == %{"2026-10-18" => 2, "2026-10-19" => 3}
    assert resumen.por_raza == %{"Chihuahua" => 2, "Criollo" => 1, "Dálmata" => 1, "Pastor" => 1}

    # Comprueba que el top de colores ordena correctamente por frecuencia mayor
    assert hd(resumen.top_colores) == %{nombre: "Negro", total: 3}
  end

  test "Función de orden superior contar_por acepta extractores personalizados" do
    perros = [
      build_perro(1, "Rex", "Pastor", "Negro", ~N[2026-10-18 10:00:00]),
      build_perro(2, "Roco", "Pug", "Dorado", ~N[2026-10-19 10:00:00])
    ]

    # Extractor personalizado: agrupar por longitud del nombre del perro
    extractor_longitud = fn %Avistamiento{nombre: n} -> String.length(n) end
    resultado = Estadisticas.contar_por(perros, extractor_longitud)

    # "Rex" tiene 3 letras, "Roco" tiene 4 letras
    assert resultado == %{3 => 1, 4 => 1}
  end
end
