defmodule Perritos.Zonas do
  @moduledoc """
  Núcleo puro para la Funcionalidad 4: Zonas de concentración.
  Convierte coordenadas en celdas de ~500m y cuenta los perritos en cada una.
  """

  # 500 metros equivalen aproximadamente a 0.0045 grados decimales en Saltillo
  @tamano_celda 0.0045

  @doc """
  Convierte coordenadas en una celda (esquina inferior izquierda).
  Cumple: Convertir coordenadas en celda es una función pura.
  
  ## Ejemplos
      iex> Perritos.Zonas.coordenadas_a_celda(25.4232, -101.0053)
      {25.4205, -101.007}
  """
  def coordenadas_a_celda(lat, lon) do
    {
      Float.round(Float.floor(lat / @tamano_celda) * @tamano_celda, 4),
      Float.round(Float.floor(lon / @tamano_celda) * @tamano_celda, 4)
    }
  end

  @doc """
  Regresa una FUNCIÓN que extrae y convierte las coordenadas de un mapa.
  Cumple: Función que regresa una función (Orden Superior).
  """
  def creador_de_celdas do
    fn %{lat: lat, lon: lon} -> coordenadas_a_celda(lat, lon) end
  end

  @doc """
  Agrupa y cuenta los perros.
  Cumple: Recibe una función (Orden Superior) y agrupa con Enum.reduce.
  """
  def agrupar_y_contar(perritos, funcion_celda) when is_function(funcion_celda, 1) do
    Enum.reduce(perritos, %{}, fn perro, acumulador ->
      celda_actual = funcion_celda.(perro)
      # Map.update suma 1 si la celda existe, o la inicializa en 1 si es nueva
      Map.update(acumulador, celda_actual, 1, &(&1 + 1))
    end)
  end

  @doc """
  Filtra avistamientos válidos (ignora los que no tengan lat/lon numéricos).
  Cumple: Recursión explícita escrita por el autor, pattern matching y 
  cláusulas múltiples (CERO uso de "if" o "cond").
  """
  # Caso 1: Lista vacía termina la recursión
  def filtrar_validos([]), do: []

  # Caso 2: El perro tiene lat y lon como flotantes (se conserva)
  def filtrar_validos([%{lat: lat, lon: lon} = perro | resto]) when is_float(lat) and is_float(lon) do
    [perro | filtrar_validos(resto)]
  end

  # Caso 3: Datos inválidos o faltantes (se ignora y se avanza al siguiente)
  def filtrar_validos([_perro_invalido | resto]) do
    filtrar_validos(resto)
  end

  @doc """
  Flujo principal que une todo el proceso.
  Cumple: Composición de datos con el operador pipe |>.
  """
  def calcular_zonas(avistamientos) do
    avistamientos
    |> filtrar_validos()
    |> agrupar_y_contar(creador_de_celdas())
  end
end