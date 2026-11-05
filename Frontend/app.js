// ============================================================
// app.js — Frontend de "Registro de Perritos de la Calle"
// ============================================================
window.onerror = function(mensaje, fuente, linea) {
    alert("Error en línea " + linea + ": " + mensaje);
};

function generarIdSeguro() {
    if (window.crypto && window.crypto.randomUUID) {
        return window.crypto.randomUUID();
    }
    return Date.now().toString(36) + Math.random().toString(36).substring(2);
}

// ---------- Estado global ----------
let idempotencyKey = generarIdSeguro();
let catalogoRazas = [];
let catalogoColores = [];
let ubicacionSeleccionada = null;

let mapaRegistro, marcadorRegistro;
window.mapaGeneral = null; // Expuesto globalmente para evitar errores de scope
let perritosCache = null;
let perrosPerdidosCache = null;

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
      if (window.mapaGeneral) {
        setTimeout(() => {
          window.mapaGeneral.invalidateSize();
          cargarPerrosPerdidosVista();
        }, 50);
      }
    });
  }
  if (viewId === "vista-lista") {
    cargarListaYMapa();
  }
  if (viewId === "vista-estadisticas") {
    cargarEstadisticas();
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

    if (selectRaza) {
      selectRaza.innerHTML = `<option value="">Sin especificar</option>` +
        catalogoRazas.map(r => `<option value="${r.id}">${r.nombre}</option>`).join("");
    }

    const opcionesColor = `<option value="">Selecciona…</option>` +
      catalogoColores.map(c => `<option value="${c.id}">${c.nombre}</option>`).join("");
    
    if (selectColorPrincipal) selectColorPrincipal.innerHTML = opcionesColor;
    if (selectExtra1) {
      selectExtra1.innerHTML = `<option value="">Ninguno</option>` +
        catalogoColores.map(c => `<option value="${c.id}">${c.nombre}</option>`).join("");
    }
    if (selectExtra2) selectExtra2.innerHTML = selectExtra1.innerHTML;

  } catch (err) {
    mostrarMensaje("registro-msg",
      "No se pudo conectar con el servidor para cargar razas y colores. Revisa que el backend esté corriendo y que API_BASE en config.js sea correcto.",
      "error");
  }
}

function actualizarColoresDisponibles() {
  const principalEl = document.getElementById("input-color-principal");
  const extra1 = document.getElementById("input-color-extra-1");
  const extra2 = document.getElementById("input-color-extra-2");
  if (!principalEl || !extra1 || !extra2) return;

  const principal = principalEl.value;
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

const colorPrinEl = document.getElementById("input-color-principal");
if (colorPrinEl) colorPrinEl.addEventListener("change", actualizarColoresDisponibles);
const colorExt1El = document.getElementById("input-color-extra-1");
if (colorExt1El) colorExt1El.addEventListener("change", actualizarColoresDisponibles);
const colorExt2El = document.getElementById("input-color-extra-2");
if (colorExt2El) colorExt2El.addEventListener("change", actualizarColoresDisponibles);

// ============================================================
// FOTO
// ============================================================
const inputFoto = document.getElementById("input-foto");
const previewFoto = document.getElementById("preview-foto");

if (inputFoto && previewFoto) {
  inputFoto.addEventListener("change", () => {
    const archivo = inputFoto.files[0];
    if (!archivo) {
      previewFoto.hidden = true;
      return;
    }
    previewFoto.src = URL.createObjectURL(archivo);
    previewFoto.hidden = false;
    const errFoto = document.getElementById("err-foto");
    if (errFoto) errFoto.textContent = "";
  });
}

// ============================================================
// MAPA DE REGISTRO
// ============================================================
function iniciarMapaRegistro() {
  const mapElem = document.getElementById("mapa-registro");
  if (!mapElem) return;

  mapaRegistro = L.map("mapa-registro").setView([25.4232, -101.0053], 13);

  L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
    attribution: "&copy; OpenStreetMap"
  }).addTo(mapaRegistro);

  marcadorRegistro = L.marker([25.4232, -101.0053], { draggable: true }).addTo(mapaRegistro);

  marcadorRegistro.on("dragend", () => {
    const pos = marcadorRegistro.getLatLng();
    ubicacionSeleccionada = { lat: pos.lat, lng: pos.lng };
    const errUbicacion = document.getElementById("err-ubicacion");
    if (errUbicacion) errUbicacion.textContent = "";
  });

  mapaRegistro.on("click", (e) => {
    marcadorRegistro.setLatLng(e.latlng);
    ubicacionSeleccionada = { lat: e.latlng.lat, lng: e.latlng.lng };
    const errUbicacion = document.getElementById("err-ubicacion");
    if (errUbicacion) errUbicacion.textContent = "";
  });
}

const btnMiUbicacion = document.getElementById("btn-mi-ubicacion");
if (btnMiUbicacion) {
  btnMiUbicacion.addEventListener("click", () => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (pos) => {
          const { latitude, longitude } = pos.coords;
          ubicacionSeleccionada = { lat: latitude, lng: longitude };
          mapaRegistro.setView([latitude, longitude], 16);
          marcadorRegistro.setLatLng([latitude, longitude]);
          const errUbicacion = document.getElementById("err-ubicacion");
          if (errUbicacion) errUbicacion.textContent = "";
        },
        () => {
          mostrarMensaje("registro-msg", "No se pudo obtener tu ubicación.", "error");
        }
      );
    }
  });
}

// ============================================================
// ENVÍO DEL FORMULARIO
// ============================================================
const form = document.getElementById("form-registro");
if (form) {
  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    limpiarErrores();

    if (!idempotencyKey) idempotencyKey = generarIdSeguro();

    const nombre = document.getElementById("input-nombre").value.trim();
    const idRaza = document.getElementById("input-raza").value;
    const idColorPrincipal = document.getElementById("input-color-principal").value;
    const colorExtra1 = document.getElementById("input-color-extra-1").value;
    const colorExtra2 = document.getElementById("input-color-extra-2").value;
    const archivoFoto = inputFoto ? inputFoto.files[0] : null;

    let valido = true;
    if (!archivoFoto) { document.getElementById("err-foto").textContent = "Falta la foto."; valido = false; }
    if (!nombre) { document.getElementById("err-nombre").textContent = "Falta el nombre."; valido = false; }
    if (!idColorPrincipal) { document.getElementById("err-color-principal").textContent = "Elige un color."; valido = false; }
    if (!ubicacionSeleccionada) { document.getElementById("err-ubicacion").textContent = "Falta marcar ubicación."; valido = false; }
    if (!valido) return;

    const btn = document.getElementById("btn-enviar");
    btn.disabled = true;
    btn.textContent = "Guardando…";

    const datos = new FormData();
    datos.append("idempotency_key", idempotencyKey);
    datos.append("nombre", nombre);
    datos.append("latitud", ubicacionSeleccionada.lat);
    datos.append("longitud", ubicacionSeleccionada.lng);
    datos.append("id_color_principal", idColorPrincipal);
    if (idRaza) datos.append("id_raza", idRaza);
    [colorExtra1, colorExtra2].forEach(c => { if (c) datos.append("colores_adicionales", c); });
    datos.append("foto", archivoFoto);

    try {
      const resp = await fetch(`${API_BASE}/api/perritos`, { method: "POST", body: datos });
      if (!resp.ok) throw new Error("El servidor rechazó el registro.");
      mostrarMensaje("registro-msg", "¡Perrito registrado con éxito!", "ok");
      form.reset();
      previewFoto.hidden = true;
      idempotencyKey = generarIdSeguro();
      ubicacionSeleccionada = null;
      perritosCache = null;
      perrosPerdidosCache = null;
    } catch (err) {
      mostrarMensaje("registro-msg", err.message || "Error de conexión.", "error");
    } finally {
      btn.disabled = false;
      btn.textContent = "Guardar registro";
    }
  });
}

// ============================================================
// LISTA, MAPA Y PERROS PERDIDOS DE VISTA
// ============================================================
function nombrePorId(catalogo, id) {
  if (id === null || id === undefined || id === "") return null;
  const item = catalogo.find(c => String(c.id) === String(id));
  return item ? item.nombre : null;
}

async function cargarListaYMapa() {
  await catalogosPromise; 
  if (perritosCache) {
    pintarLista(perritosCache);
    pintarMapaGeneral(perritosCache);
  }
  try {
    const resp = await fetch(`${API_BASE}/api/perritos`);
    if (!resp.ok) throw new Error();
    perritosCache = await resp.json();
    pintarLista(perritosCache);
    pintarMapaGeneral(perritosCache);
  } catch (err) {
    console.error("Error al cargar perritos:", err);
  }

  await cargarPerrosPerdidosVista();
}

async function cargarPerrosPerdidosVista() {
  try {
    const resp = await fetch(`${ELIXIR_BASE}/perros-perdidos?dias=7`);
    if (!resp.ok) throw new Error("Error al obtener perros perdidos de vista");
    perrosPerdidosCache = await resp.json();
    pintarPerrosPerdidosEnMapa(perrosPerdidosCache);
  } catch (err) {
    console.error("No se pudieron cargar los perros perdidos de vista:", err);
  }
}

function pintarLista(perritos) {
  const cont = document.getElementById("lista-perritos");
  if (!cont) return;
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
  const mapGeneralElem = document.getElementById("mapa-general");
  if (!mapGeneralElem) return;

  if (!window.mapaGeneral) {
    window.mapaGeneral = L.map("mapa-general").setView([25.4232, -101.0053], 12);
    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: "&copy; OpenStreetMap"
    }).addTo(window.mapaGeneral);
  }
  
  window.mapaGeneral.eachLayer(layer => {
    if (layer instanceof L.Marker || layer instanceof L.Circle) window.mapaGeneral.removeLayer(layer);
  });

  const idsPerdidos = new Set((perrosPerdidosCache || []).map(p => String(p.id || p.id_perrito)));

  perritos.forEach(p => {
    const pId = String(p.id_perrito || p.id);
    if (idsPerdidos.has(pId)) return;

    const marker = L.marker([p.latitud, p.longitud]).addTo(window.mapaGeneral);
    const colorNombre = nombrePorId(catalogoColores, p.id_color_principal) || "";
    marker.bindPopup(`
      <strong>${p.nombre}</strong><br>
      <img src="${API_BASE}/api/imagenes/${p.foto_ruta}" style="width:100px;border-radius:6px;margin-top:4px;"><br>
      ${colorNombre}
    `);
  });

  fetch(`${ELIXIR_BASE}/zonas`)
    .then(response => response.json())
    .then(zonas => {
        zonas.forEach(zona => {
            L.circle([zona.latitud, zona.longitud], {
                color: 'red',
                fillColor: '#f03',
                fillOpacity: 0.3,
                radius: zona.radio || 600
            }).addTo(window.mapaGeneral);
        });
    })
    .catch(error => console.error("Error al cargar zonas de Elixir:", error));

  if (perrosPerdidosCache) {
    pintarPerrosPerdidosEnMapa(perrosPerdidosCache);
  }
}

function pintarPerrosPerdidosEnMapa(perdidos) {
  if (!window.mapaGeneral || !perdidos) return;

  perdidos.forEach(p => {
    const iconoPerdido = L.divIcon({
      className: 'custom-lost-marker',
      html: '<div style="background-color: #f59e0b; width: 16px; height: 16px; border-radius: 50%; border: 2px solid white; box-shadow: 0 0 4px rgba(0,0,0,0.4);"></div>',
      iconSize: [16, 16],
      iconAnchor: [8, 8]
    });

    const marker = L.marker([p.lat, p.lon], { icon: iconoPerdido }).addTo(window.mapaGeneral);
    
    marker.bindPopup(`
      <div style="text-align: center;">
        <strong style="color: #d97706;">⚠️ Perdido de vista (>7 días)</strong><br>
        <strong>${p.nombre || 'Sin nombre'}</strong><br>
        <img src="${API_BASE}/api/imagenes/${p.foto}" style="width:90px;border-radius:6px;margin-top:4px;"><br>
        <span style="font-size: 11px; color: #666;">Registrado hace más de una semana</span>
      </div>
    `);
  });
}

// ============================================================
// ESTADÍSTICAS (Funcionalidad de Santiago)
// ============================================================
async function cargarEstadisticas() {
  const msgEl = document.getElementById("stats-msg");
  if (msgEl) msgEl.hidden = true;

  try {
    const url = (typeof ELIXIR_BASE !== "undefined" ? ELIXIR_BASE : "/f") + "/estadisticas";
    const resp = await fetch(url);
    if (!resp.ok) throw new Error("No se pudo obtener las estadísticas de Elixir.");
    const data = await resp.json();

    const elTotal = document.getElementById("stat-total");
    if (elTotal) elTotal.textContent = data.total_avistamientos || 0;

    const topRaza = data.top_razas && data.top_razas.length > 0 ? data.top_razas[0].nombre : "Sin datos";
    const topColor = data.top_colores && data.top_colores.length > 0 ? data.top_colores[0].nombre : "Sin datos";

    const elTopRaza = document.getElementById("stat-top-raza");
    const elTopColor = document.getElementById("stat-top-color");
    if (elTopRaza) elTopRaza.textContent = topRaza;
    if (elTopColor) elTopColor.textContent = topColor;

    renderizarBarras("chart-razas", data.top_razas, data.total_avistamientos);
    renderizarBarras("chart-colores", data.top_colores, data.total_avistamientos);

  } catch (err) {
    if (msgEl) {
      msgEl.textContent = "Error al conectar con el servicio Elixir (/f/estadisticas): " + err.message;
      msgEl.className = "msg error";
      msgEl.hidden = false;
    }
  }
}

function renderizarBarras(containerId, items, totalGeneral) {
  const cont = document.getElementById(containerId);
  if (!cont) return;
  if (!items || items.length === 0 || !totalGeneral) {
    cont.innerHTML = `<p class="hint">No hay datos suficientes para graficar.</p>`;
    return;
  }

  const maxVal = Math.max(...items.map(i => i.total), 1);

  cont.innerHTML = items.map(item => {
    const porcentaje = Math.round((item.total / totalGeneral) * 100);
    const anchoBarra = Math.round((item.total / maxVal) * 100);
    return `
      <div class="bar-row">
        <div class="bar-info">
          <span class="bar-name">${item.nombre}</span>
          <span class="bar-val">${item.total} (${porcentaje}%)</span>
        </div>
        <div class="bar-track">
          <div class="bar-fill" style="width: ${anchoBarra}%;"></div>
        </div>
      </div>
    `;
  }).join("");
}

// ============================================================
// MODAL DE DETALLE Y UTILIDADES
// ============================================================
function abrirDetalle(perrito) {
  if (!perrito) return;
  const razaNombre = nombrePorId(catalogoRazas, perrito.id_raza) || "Sin raza definida";
  const colorNombre = nombrePorId(catalogoColores, perrito.id_color_principal) || "—";
  
  const detFoto = document.getElementById("detalle-foto");
  if (detFoto) detFoto.src = `${API_BASE}/api/imagenes/${perrito.foto_ruta}`;
  
  const detNombre = document.getElementById("detalle-nombre");
  if (detNombre) detNombre.textContent = perrito.nombre;
  
  const detRaza = document.getElementById("detalle-raza");
  if (detRaza) detRaza.textContent = razaNombre;
  
  const detColores = document.getElementById("detalle-colores");
  if (detColores) detColores.textContent = colorNombre;
  
  const detFecha = document.getElementById("detalle-fecha");
  if (detFecha) detFecha.textContent = perrito.fecha_registro || "—";
  
  const modalDetalle = document.getElementById("modal-detalle");
  if (modalDetalle) modalDetalle.hidden = false;
}

const cerrarModalBtn = document.getElementById("cerrar-modal");
if (cerrarModalBtn) {
  cerrarModalBtn.addEventListener("click", () => {
    const modalDetalle = document.getElementById("modal-detalle");
    if (modalDetalle) modalDetalle.hidden = true;
  });
}

function mostrarMensaje(elId, texto, tipo) {
  const el = document.getElementById(elId);
  if (!el) return;
  el.textContent = texto;
  el.className = `msg ${tipo}`;
  el.hidden = false;
}

function limpiarErrores() {
  document.querySelectorAll(".error").forEach(e => e.textContent = "");
  const regMsg = document.getElementById("registro-msg");
  if (regMsg) regMsg.hidden = true;
}

// ============================================================
// INICIO
// ============================================================
const catalogosPromise = cargarCatalogos(); 
iniciarMapaRegistro();