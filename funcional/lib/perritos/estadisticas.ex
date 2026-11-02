defmodule Perritos.Estadisticas do
  @moduledoc """
  Núcleo puro de la funcionalidad: Estadísticas de Avistamientos.

  Todas las funciones de este módulo son puras:
  - Reciben únicamente datos (listas, mapas, structs).
  - Regresan únicamente datos transformados.
  - Cero efectos secundarios (sin consultas SQL, sin HTTP, sin llamadas al reloj del sistema).
  - Cero estado mutable.
  """

  alias Perritos.Avistamiento

  # ============================================================================
  # 1. ORDEN SUPERIOR: Funciones generadoras y consumidoras de funciones
  # ============================================================================

  @doc """
  Función de Orden Superior (Generadora):
  Regresa una **función extractora** según el criterio solicitado (`:raza`, `:color`, `:fecha`).

  ## Ejemplos

      iex> extractor = Perritos.Estadisticas.criterio_extractor(:raza)
      iex> extractor.(%Perritos.Avistamiento{raza: "Pug"})
      "Pug"

      iex> extractor = Perritos.Estadisticas.criterio_extractor(:raza)
      iex> extractor.(%Perritos.Avistamiento{raza: nil})
      "Sin raza definida"
  """
  def criterio_extractor(:raza) do
    fn
      %Avistamiento{raza: nil} -> "Sin raza definida"
      %Avistamiento{raza: ""} -> "Sin raza definida"
      %Avistamiento{raza: r} -> r
    end
  end

  def criterio_extractor(:color) do
    fn
      %Avistamiento{color_principal: nil} -> "Sin color especificado"
      %Avistamiento{color_principal: c} -> c
    end
  end

  def criterio_extractor(:fecha) do
    fn %Avistamiento{fecha: %NaiveDateTime{} = f} ->
      NaiveDateTime.to_date(f) |> Date.to_iso8601()
    end
  end

  @doc """
  Función de Orden Superior (Consumidora):
  Recibe una lista de avistamientos y una **función extractora**, y cuenta
  cuántos elementos caen en cada categoría devuelta por la función.

  ## Ejemplos

      iex> lista = [
      ...>   %Perritos.Avistamiento{raza: "Pug"},
      ...>   %Perritos.Avistamiento{raza: "Pug"},
      ...>   %Perritos.Avistamiento{raza: "Chihuahua"}
      ...> ]
      iex> Perritos.Estadisticas.contar_por(lista, fn a -> a.raza end)
      %{"Chihuahua" => 1, "Pug" => 2}
  """
  def contar_por(avistamientos, extractor) when is_list(avistamientos) and is_function(extractor, 1) do
    Enum.reduce(avistamientos, %{}, fn item, acc ->
      clave = extractor.(item)
      Map.update(acc, clave, 1, &(&1 + 1))
    end)
  end

  # ============================================================================
  # 2. CONTEOS DIRECTOS POR CRITERIO (Composición con pipelines |>)
  # ============================================================================

  @doc """
  Cuenta perritos agrupados por su raza.

  ## Ejemplos

      iex> lista = [
      ...>   %Perritos.Avistamiento{raza: "Chihuahua"},
      ...>   %Perritos.Avistamiento{raza: nil}
      ...> ]
      iex> Perritos.Estadisticas.contar_por_raza(lista)
      %{"Chihuahua" => 1, "Sin raza definida" => 1}
  """
  def contar_por_raza(avistamientos) when is_list(avistamientos) do
    contar_por(avistamientos, criterio_extractor(:raza))
  end

  @doc """
  Cuenta perritos agrupados por su color principal.

  ## Ejemplos

      iex> lista = [
      ...>   %Perritos.Avistamiento{color_principal: "Negro"},
      ...>   %Perritos.Avistamiento{color_principal: "Negro"},
      ...>   %Perritos.Avistamiento{color_principal: "Café"}
      ...> ]
      iex> Perritos.Estadisticas.contar_por_color(lista)
      %{"Café" => 1, "Negro" => 2}
  """
  def contar_por_color(avistamientos) when is_list(avistamientos) do
    contar_por(avistamientos, criterio_extractor(:color))
  end

  @doc """
  Cuenta avistamientos agrupados por día (formato YYYY-MM-DD).

  ## Ejemplos

      iex> lista = [
      ...>   %Perritos.Avistamiento{fecha: ~N[2026-10-20 10:00:00]},
      ...>   %Perritos.Avistamiento{fecha: ~N[2026-10-20 18:30:00]},
      ...>   %Perritos.Avistamiento{fecha: ~N[2026-10-21 08:00:00]}
      ...> ]
      iex> Perritos.Estadisticas.contar_por_dia(lista)
      %{"2026-10-20" => 2, "2026-10-21" => 1}
  """
  def contar_por_dia(avistamientos) when is_list(avistamientos) do
    contar_por(avistamientos, criterio_extractor(:fecha))
  end

  # ============================================================================
  # 3. RECURSIÓN EXPLÍCITA: Tomar los Top N elementos
  # ============================================================================

  @doc """
  Ordena un mapa de frecuencias de mayor a menor y toma recursivamente los primeros `n` elementos.

  Implementado con **recursión explícita sobre la cabeza y la cola de la lista**,
  sin usar atajos mutables.

  ## Ejemplos

      iex> frecs = %{"Negro" => 10, "Blanco" => 3, "Café" => 25, "Gris" => 1}
      iex> Perritos.Estadisticas.top_n(frecs, 2)
      [{"Café", 25}, {"Negro", 10}]

      iex> Perritos.Estadisticas.top_n(%{}, 5)
      []
  """
  def top_n(conteo_map, n) when is_map(conteo_map) and is_integer(n) and n >= 0 do
    conteo_map
    |> Map.to_list()
    |> Enum.sort_by(fn {_clave, total} -> total end, :desc)
    |> tomar_recursivo(n, [])
  end

  # Cláusulas recursivas explícitas:
  # Caso base 1: ya juntamos N elementos requeridos (n == 0)
  defp tomar_recursivo(_lista, 0, acumulador), do: Enum.reverse(acumulador)
  # Caso base 2: la lista se vació antes de llegar a N
  defp tomar_recursivo([], _n, acumulador), do: Enum.reverse(acumulador)
  # Caso recursivo: tomamos la cabeza, decrementamos n en 1, y seguimos con la cola
  defp tomar_recursivo([cabeza | resto], n, acumulador) do
    tomar_recursivo(resto, n - 1, [cabeza | acumulador])
  end

  # ============================================================================
  # 4. PATTERN MATCHING & RESUMEN INTEGRAL (Pipelines |>)
  # ============================================================================

  @doc """
  Calcula el resumen estadístico general para alimentar el dashboard del frontend.
  Maneja pattern matching con cláusulas múltiples:
  - Maneja explícitamente lista vacía `[]`.
  - Maneja lista con elementos `[_ | _]`.

  ## Ejemplos

      iex> Perritos.Estadisticas.resumen([])
      %{total_avistamientos: 0, por_raza: %{}, por_color: %{}, por_dia: %{}, top_razas: [], top_colores: []}
  """
  def resumen([]) do
    %{
      total_avistamientos: 0,
      por_raza: %{},
      por_color: %{},
      por_dia: %{},
      top_razas: [],
      top_colores: []
    }
  end

  def resumen(avistamientos) when is_list(avistamientos) do
    razas = contar_por_raza(avistamientos)
    colores = contar_por_color(avistamientos)
    dias = contar_por_dia(avistamientos)

    %{
      total_avistamientos: length(avistamientos),
      por_raza: razas,
      por_color: colores,
      por_dia: dias,
      top_razas: top_n(razas, 5) |> Enum.map(&formatear_par/1),
      top_colores: top_n(colores, 5) |> Enum.map(&formatear_par/1)
    }
  end

  # Convierte la tupla {"Pug", 4} en mapa legible para JSON %{nombre: "Pug", total: 4}
  defp formatear_par({nombre, total}), do: %{nombre: nombre, total: total}
end
