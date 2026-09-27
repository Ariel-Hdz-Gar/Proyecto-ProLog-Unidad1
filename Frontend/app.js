// ============================================================
// app.js — Frontend de "Registro de Perritos de la Calle"
// ============================================================
// Depende de config.js (variable API_BASE) y Leaflet (cargado en index.html)

// ---------- Estado global ----------
let idempotencyKey = crypto.randomUUID();   // se regenera solo tras un envío exitoso
let catalogoRazas = [];
let catalogoColores = [];
let ubicacionSeleccionada = null;           // { lat, lng }

let mapaRegistro, marcadorRegistro;
let mapaGeneral;
let perritosCache = null;

// ============================================================
// NAVEGACIÓN ENTRE VISTAS
// ============================================================
document.querySelectorAll(".tab-btn").forEach(btn => {
  btn.addEventListener("click", () => cambiarVista(btn.dataset.view));
});

function cambiarVista(viewId) {
  document.querySelectorAll(".view").forEach(v => v.classList.remove("active"));
  document.querySelectorAll(".tab-btn").forEach(b => b.classList.remove("active"));
  document.getElementById(viewId).classList.add("active");
  document.querySelector(`.tab-btn[data-view="${viewId}"]`).classList.add("active");

  if (viewId === "vista-mapa") {
    cargarListaYMapa().then(() => {
      // Leaflet necesita saber su tamaño real cuando el contenedor
      // estaba oculto (display:none) al inicializarse.
      if (mapaGeneral) setTimeout(() => mapaGeneral.invalidateSize(), 50);
    });
  }
  if (viewId === "vista-lista") {
    cargarListaYMapa();
  }
}

// ============================================================
// CATÁLOGOS (razas y colores)
// ============================================================
async function cargarCatalogos() {
  const selectRaza = document.getElementById("input-raza");
  const selectColorPrincipal = document.getElementById("input-color-principal");
  const selectExtra1 = document.getElementById("input-color-extra-1");
  const selectExtra2 = document.getElementById("input-color-extra-2");

  try {
    const resp = await fetch(`${API_BASE}/api/catalogos`);
    if (!resp.ok) throw new Error("No se pudo cargar el catálogo");
    const data = await resp.json();
    catalogoRazas = data.razas || [];
    catalogoColores = data.colores || [];

    selectRaza.innerHTML = `<option value="">Sin especificar</option>` +
      catalogoRazas.map(r => `<option value="${r.id}">${r.nombre}</option>`).join("");

    const opcionesColor = `<option value="">Selecciona…</option>` +
      catalogoColores.map(c => `<option value="${c.id}">${c.nombre}</option>`).join("");
    selectColorPrincipal.innerHTML = opcionesColor;
    selectExtra1.innerHTML = `<option value="">Ninguno</option>` +
      catalogoColores.map(c => `<option value="${c.id}">${c.nombre}</option>`).join("");
    selectExtra2.innerHTML = selectExtra1.innerHTML;

  } catch (err) {
    mostrarMensaje("registro-msg",
      "No se pudo conectar con el servidor para cargar razas y colores. Revisa que el backend esté corriendo y que API_BASE en config.js sea correcto.",
      "error");
  }
}

// Evita que el usuario repita un color entre principal / extra1 / extra2
function actualizarColoresDisponibles() {
  const principal = document.getElementById("input-color-principal").value;
  const extra1 = document.getElementById("input-color-extra-1");
  const extra2 = document.getElementById("input-color-extra-2");
  const valExtra1 = extra1.value;
  const valExtra2 = extra2.value;

  const usados = new Set([principal, valExtra1, valExtra2].filter(v => v));

  [[extra1, valExtra1], [extra2, valExtra2]].forEach(([select, valorActual]) => {
    select.innerHTML = `<option value="">Ninguno</option>` +
      catalogoColores
        .filter(c => String(c.id) === valorActual || !usados.has(String(c.id)))
        .map(c => `<option value="${c.id}" ${String(c.id) === valorActual ? "selected" : ""}>${c.nombre}</option>`)
        .join("");
  });
}
document.getElementById("input-color-principal").addEventListener("change", actualizarColoresDisponibles);
document.getElementById("input-color-extra-1").addEventListener("change", actualizarColoresDisponibles);
document.getElementById("input-color-extra-2").addEventListener("change", actualizarColoresDisponibles);

// ============================================================
// FOTO — cámara o galería, con vista previa
// ============================================================
const inputFoto = document.getElementById("input-foto");
const previewFoto = document.getElementById("preview-foto");

inputFoto.addEventListener("change", () => {
  const archivo = inputFoto.files[0];
  if (!archivo) {
    previewFoto.hidden = true;
    return;
  }
  previewFoto.src = URL.createObjectURL(archivo);
  previewFoto.hidden = false;
  document.getElementById("err-foto").textContent = "";
});

// ============================================================
// MAPA DE REGISTRO — pin arrastrable + geolocalización
// ============================================================
function iniciarMapaRegistro() {
  mapaRegistro = L.map("mapa-registro").setView([25.4232, -101.0053], 13); // Saltillo por defecto

  L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
    attribution: "&copy; OpenStreetMap"
  }).addTo(mapaRegistro);

  marcadorRegistro = L.marker([25.4232, -101.0053], { draggable: true }).addTo(mapaRegistro);

  marcadorRegistro.on("dragend", () => {
    const pos = marcadorRegistro.getLatLng();
    ubicacionSeleccionada = { lat: pos.lat, lng: pos.lng };
    document.getElementById("err-ubicacion").textContent = "";
  });

  mapaRegistro.on("click", (e) => {
    marcadorRegistro.setLatLng(e.latlng);
    ubicacionSeleccionada = { lat: e.latlng.lat, lng: e.latlng.lng };
    document.getElementById("err-ubicacion").textContent = "";
  });
}

document.getElementById("btn-mi-ubicacion").addEventListener("click", () => {
  if (!navigator.geolocation) {
    mostrarMensaje("registro-msg", "Tu navegador no soporta geolocalización.", "error");
    return;
  }
  navigator.geolocation.getCurrentPosition(
    (pos) => {
      const { latitude, longitude } = pos.coords;
      ubicacionSeleccionada = { lat: latitude, lng: longitude };
      mapaRegistro.setView([latitude, longitude], 16);
      marcadorRegistro.setLatLng([latitude, longitude]);
      document.getElementById("err-ubicacion").textContent = "";
    },
    () => {
      mostrarMensaje("registro-msg",
        "No se pudo obtener tu ubicación. Revisa los permisos del navegador, o mueve el pin a mano tocando el mapa. " +
        "Recuerda: esto solo funciona en HTTPS o localhost.", "error");
    }
  );
});

// ============================================================
// ENVÍO DEL FORMULARIO
// ============================================================
const form = document.getElementById("form-registro");

form.addEventListener("submit", async (e) => {
  e.preventDefault();
  limpiarErrores();

  const nombre = document.getElementById("input-nombre").value.trim();
  const idRaza = document.getElementById("input-raza").value;
  const idColorPrincipal = document.getElementById("input-color-principal").value;
  const colorExtra1 = document.getElementById("input-color-extra-1").value;
  const colorExtra2 = document.getElementById("input-color-extra-2").value;
  const archivoFoto = inputFoto.files[0];

  let valido = true;

  if (!archivoFoto) {
    document.getElementById("err-foto").textContent = "Falta la foto.";
    valido = false;
  }
  if (!nombre) {
    document.getElementById("err-nombre").textContent = "Falta el nombre.";
    valido = false;
  }
  if (!idColorPrincipal) {
    document.getElementById("err-color-principal").textContent = "Elige un color principal.";
    valido = false;
  }
  if (!ubicacionSeleccionada) {
    document.getElementById("err-ubicacion").textContent = "Falta marcar la ubicación en el mapa.";
    valido = false;
  }
  if (!valido) return;

  const btn = document.getElementById("btn-enviar");
  btn.disabled = true;
  btn.textContent = "Guardando…";

  // IMPORTANTE: idempotency_key va DENTRO del FormData, como campo normal,
  // porque así lo espera el backend (idempotency_key: str = Form(...)).
  // NO va como header — un header no llega a ese parámetro.
  const datos = new FormData();
  datos.append("idempotency_key", idempotencyKey);
  datos.append("nombre", nombre);
  datos.append("latitud", ubicacionSeleccionada.lat);
  datos.append("longitud", ubicacionSeleccionada.lng);
  datos.append("id_color_principal", idColorPrincipal);
  if (idRaza) datos.append("id_raza", idRaza);
  [colorExtra1, colorExtra2].forEach(c => {
    if (c) datos.append("colores_adicionales", c);
  });
  datos.append("foto", archivoFoto);

  try {
    // Ojo: la ruta lleva /api/perritos, no /perritos.
    const resp = await fetch(`${API_BASE}/api/perritos`, { method: "POST", body: datos });
    if (!resp.ok) {
      const errData = await resp.json().catch(() => ({}));
      throw new Error(errData.detail || "El servidor rechazó el registro.");
    }
    mostrarMensaje("registro-msg", "¡Perrito registrado con éxito!", "ok");
    form.reset();
    previewFoto.hidden = true;
    idempotencyKey = crypto.randomUUID(); // nueva key para el siguiente registro
    ubicacionSeleccionada = null;
    perritosCache = null; // fuerza a recargar la lista/mapa con el nuevo perrito
  } catch (err) {
    mostrarMensaje("registro-msg", err.message || "No se pudo conectar con el servidor.", "error");
    // OJO: la idempotency_key NO se regenera aquí a propósito.
    // Si el usuario reintenta, se manda la misma key y el backend
    // no debe crear un segundo registro duplicado.
  } finally {
    btn.disabled = false;
    btn.textContent = "Guardar registro";
  }
});

// ============================================================
// LISTA + MAPA GENERAL
// ============================================================

// El backend regresa id_raza / id_color_principal como NÚMEROS (SELECT * crudo),
// no como nombres. Los traducimos aquí usando los catálogos que ya cargamos
// para el formulario. Si en algún momento Ariel agrega el JOIN en el backend
// y regresa el nombre directo, esta función simplemente deja de usarse.
function nombrePorId(catalogo, id) {
  if (id === null || id === undefined || id === "") return null;
  const item = catalogo.find(c => String(c.id) === String(id));
  return item ? item.nombre : null;
}

async function cargarListaYMapa() {
  await catalogosPromise; // asegura que catalogoRazas/catalogoColores ya estén listos
  if (perritosCache) {
    pintarLista(perritosCache);
    pintarMapaGeneral(perritosCache);
    return;
  }
  try {
    const resp = await fetch(`${API_BASE}/api/perritos`);
    if (!resp.ok) throw new Error();
    perritosCache = await resp.json();
    pintarLista(perritosCache);
    pintarMapaGeneral(perritosCache);
  } catch (err) {
    mostrarMensaje("lista-msg",
      "No se pudo cargar la lista de perritos. Revisa que el backend esté corriendo y tenga el endpoint GET /api/perritos.",
      "error");
  }
}

function pintarLista(perritos) {
  const cont = document.getElementById("lista-perritos");
  if (!perritos || perritos.length === 0) {
    cont.innerHTML = `<p class="hint">Todavía no hay perritos registrados.</p>`;
    return;
  }
  cont.innerHTML = perritos.map(p => {
    const razaNombre = nombrePorId(catalogoRazas, p.id_raza) || "Sin raza definida";
    return `
      <div class="card-perrito" data-id="${p.id_perrito}">
        <img src="${API_BASE}/api/imagenes/${p.foto_ruta}" alt="${p.nombre}">
        <div class="card-info">
          <h3>${p.nombre}</h3>
          <p>${razaNombre}</p>
        </div>
      </div>
    `;
  }).join("");

  cont.querySelectorAll(".card-perrito").forEach(card => {
    card.addEventListener("click", () => {
      const perrito = perritos.find(p => String(p.id_perrito) === card.dataset.id);
      abrirDetalle(perrito);
    });
  });
}

function pintarMapaGeneral(perritos) {
  if (!mapaGeneral) {
    mapaGeneral = L.map("mapa-general").setView([25.4232, -101.0053], 12);
    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: "&copy; OpenStreetMap"
    }).addTo(mapaGeneral);
  }
  // Limpia pines anteriores antes de repintar
  mapaGeneral.eachLayer(layer => {
    if (layer instanceof L.Marker) mapaGeneral.removeLayer(layer);
  });

  perritos.forEach(p => {
    const marker = L.marker([p.latitud, p.longitud]).addTo(mapaGeneral);
    const colorNombre = nombrePorId(catalogoColores, p.id_color_principal) || "";
    marker.bindPopup(`
      <strong>${p.nombre}</strong><br>
      <img src="${API_BASE}/api/imagenes/${p.foto_ruta}" style="width:100px;border-radius:6px;margin-top:4px;"><br>
      ${colorNombre}
    `);
  });
}

// ============================================================
// MODAL DE DETALLE
// ============================================================
function abrirDetalle(perrito) {
  if (!perrito) return;
  const razaNombre = nombrePorId(catalogoRazas, perrito.id_raza) || "Sin raza definida";
  const colorNombre = nombrePorId(catalogoColores, perrito.id_color_principal) || "—";
  document.getElementById("detalle-foto").src = `${API_BASE}/api/imagenes/${perrito.foto_ruta}`;
  document.getElementById("detalle-nombre").textContent = perrito.nombre;
  document.getElementById("detalle-raza").textContent = razaNombre;
  // NOTA: el backend aún no regresa los colores adicionales (viven en otra
  // tabla y el SELECT actual no las trae). Por ahora solo mostramos el
  // color principal. Pídele a Ariel un JOIN o un segundo query si los quieren aquí.
  document.getElementById("detalle-colores").textContent = colorNombre;
  document.getElementById("detalle-fecha").textContent = perrito.fecha_registro || "—";
  document.getElementById("modal-detalle").hidden = false;
}
document.getElementById("cerrar-modal").addEventListener("click", () => {
  document.getElementById("modal-detalle").hidden = true;
});

// ============================================================
// UTILIDADES
// ============================================================
function mostrarMensaje(elId, texto, tipo) {
  const el = document.getElementById(elId);
  el.textContent = texto;
  el.className = `msg ${tipo}`;
  el.hidden = false;
}
function limpiarErrores() {
  document.querySelectorAll(".error").forEach(e => e.textContent = "");
  document.getElementById("registro-msg").hidden = true;
}

// ============================================================
// INICIO
// ============================================================
const catalogosPromise = cargarCatalogos(); // se usa para esperar catálogos antes de pintar lista/mapa
iniciarMapaRegistro();