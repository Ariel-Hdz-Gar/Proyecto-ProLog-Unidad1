defmodule Perritos.ZonasTest do
  use ExUnit.Case, async: true
  alias Perritos.Zonas

  # Prueba 1 (Caso borde): Lista vacía
  test "calcular_zonas con lista vacía regresa mapa vacío" do
    assert Zonas.calcular_zonas([]) == %{}
  end

  # Prueba 2 (Caso borde): Filtrado correcto mediante pattern matching
  test "ignora perritos con coordenadas inválidas o faltantes" do
    invalidos = [
      %{nombre: "Firulais", lat: nil, lon: -101.0},
      %{nombre: "Solovino", lat: "25.0", lon: "-101.0"}, # Textos en lugar de flotantes
      %{nombre: "Chato"} # Faltan completamente las llaves lat y lon
    ]
    assert Zonas.calcular_zonas(invalidos) == %{}
  end

  # Prueba 3: Conteo y agrupación (Enum.reduce)
  test "agrupa perritos cercanos sumándolos en la misma celda" do
    perritos = [
      %{lat: 25.4232, lon: -101.0053}, # Cae matemáticamente en {25.4205, -101.007}
      %{lat: 25.4211, lon: -101.0069}  # Está muy cerca, cae en la misma celda
    ]
    
    resultado = Zonas.calcular_zonas(perritos)
    
    # El mapa devuelto debe indicar que esa celda tiene exactamente 2 perritos
    assert resultado == %{{25.4205, -101.007} => 2}
  end

  # Prueba 4: Diferenciación de celdas
  test "separa perritos lejanos en celdas distintas" do
    perritos = [
      %{lat: 25.4232, lon: -101.0053}, # Cerca de la Alameda
      %{lat: 25.5000, lon: -100.9000}  # Lejos al norte
    ]
    
    resultado = Zonas.calcular_zonas(perritos)
    
    # Debemos tener 2 celdas diferentes en el mapa
    assert map_size(resultado) == 2
  end

  # Prueba 5: Orden superior (Función que regresa una función)
  test "creador_de_celdas genera una función pura evaluable" do
    funcion_creada = Zonas.creador_de_celdas()
    
    assert is_function(funcion_creada, 1)
    assert funcion_creada.(%{lat: 25.4232, lon: -101.0053}) == {25.4205, -101.007}
  end
end