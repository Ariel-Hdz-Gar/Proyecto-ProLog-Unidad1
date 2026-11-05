defmodule Perritos.Avistamiento do
  @moduledoc """
  Estructura de datos pura que representa un avistamiento de perrito.
  Solo contiene datos, sin efectos secundarios ni lógica de base de datos.
  """

  @derive Jason.Encoder
  defstruct [
    :id,
    :nombre,
    :raza,
    :color_principal,
    :colores,
    :lat,
    :lon,
    :foto,
    :fecha
  ]
end
