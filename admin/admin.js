const esc = (v) =>
  String(v ?? "").replace(
    /[&<>"']/g,
    (c) =>
      ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[
        c
      ],
  );
const $ = (s) =>
  s === "#editor"
    ? document.querySelector(".tab:not(.hidden) #editor")
    : document.querySelector(s);
let editing = null;
const tables = {
  gallery: { table: "gallery", title: "Our Designs" },
  services: { table: "services", title: "Services" },
  pricing: { table: "pricing", title: "Pricing" },
  reviews: { table: "reviews", title: "Reviews" },
};
async function init() {
  try {
    const {
      data: { session },
    } = await supabaseClient.auth.getSession();
    if (session) showApp();
  } catch (error) {
    console.error(error);
    $("#loginError").textContent =
      "Your admin session expired. Please sign in again.";
  }
  $("#loginForm").onsubmit = login;
  document
    .querySelectorAll(".nav")
    .forEach((b) => (b.onclick = () => openTab(b.dataset.tab)));
  $("#logout").onclick = async () => {
    await supabaseClient.auth.signOut();
    location.reload();
  };
  supabaseClient.auth.onAuthStateChange((event, session) => {
    if (event === "SIGNED_OUT" || (event === "TOKEN_REFRESHED" && !session))
      showLogin("Your admin session expired. Please sign in again.");
  });
  document.addEventListener("click", (event) => {
    const add = event.target.closest("[data-add-item]");
    if (add) {
      event.preventDefault();
      editor(add.dataset.addItem, null);
    }
  });
}
async function login(e) {
  e.preventDefault();
  $("#loginError").textContent = "Signing in...";
  const { error } = await supabaseClient.auth.signInWithPassword({
    email: $("#email").value.trim(),
    password: $("#password").value,
  });
  if (error) {
    console.error(error);
    $("#loginError").textContent = `Sign-in failed: ${error.message}`;
    return;
  }
  showApp();
}
function showLogin(message = "") {
  $("#appView").classList.add("hidden");
  $("#loginView").classList.remove("hidden");
  $("#loginError").textContent = message;
}
function showApp() {
  $("#loginView").classList.add("hidden");
  $("#appView").classList.remove("hidden");
  openTab("gallery");
}
function openTab(tab) {
  document.querySelectorAll(".tab").forEach((x) => x.classList.add("hidden"));
  $(`#${tab}`).classList.remove("hidden");
  document
    .querySelectorAll(".nav")
    .forEach((x) => x.classList.toggle("active", x.dataset.tab === tab));
  $("#pageTitle").textContent = tab[0].toUpperCase() + tab.slice(1);
  if (tab === "dashboard") dashboard();
  if (tables[tab]) crud(tab);
  if (tab === "settings") settings();
  if (tab === "enquiries") enquiries();
}
async function count(t) {
  const { count } = await supabaseClient
    .from(t)
    .select("*", { count: "exact", head: true });
  return count || 0;
}
async function dashboard() {
  const [g, s, p, r, e] = await Promise.all(
    ["gallery", "services", "pricing", "reviews", "enquiries"].map(count),
  );
  $("#dashboard").innerHTML =
    `<div class="grid-stats"><div class="stat"><span>Gallery Images</span><b>${g}</b></div><div class="stat"><span>Services</span><b>${s}</b></div><div class="stat"><span>Pricing Items</span><b>${p}</b></div><div class="stat"><span>Reviews</span><b>${r}</b></div></div><div class="panel" style="margin-top:15px"><h2>Enquiries</h2><p>You have <b>${e}</b> enquiry records. Customer enquiries submitted through the website appear here.</p></div>`;
}
function schema(tab) {
  if (tab === "gallery")
    return [
      { k: "design_name", l: "Design name", type: "text", req: true },
      {
        k: "category",
        l: "Category",
        type: "select",
        req: true,
        options: [
          "Simple Aari Works (₹1,000–₹1,500)",
          "Light Heavy Aari Works (₹1,500–₹2,500)",
          "Bridal Aari Works (₹3,000–₹5,000)",
          "Bridal Aari Works (₹5,000–₹8,000)",
          "Heavy Aari Works (Above ₹8,000)",
          "Machine Embroidery Work (Price on request)",
          "Pattern Blouse (Price on request)",
        ],
      },
      { k: "price", l: "Price (₹)", type: "number" },
      { k: "price_on_request", l: "Price on request", type: "checkbox" },
      { k: "description", l: "Description", type: "textarea" },
    ];
  if (tab === "services")
    return [
      { k: "name", l: "Service name", type: "text", req: true },
      { k: "starting_price", l: "Starting price (₹)", type: "number" },
      { k: "description", l: "Description", type: "textarea" },
    ];
  if (tab === "pricing")
    return [
      { k: "service_name", l: "Service name", type: "text", req: true },
      { k: "price", l: "Price (₹)", type: "number" },
      { k: "description", l: "Description", type: "textarea" },
    ];
  return [
    { k: "customer_name", l: "Customer name", type: "text", req: true },
    { k: "rating", l: "Rating (1-5)", type: "number", req: true },
    { k: "review_text", l: "Review", type: "textarea", req: true },
  ];
}
async function crud(tab) {
  const meta = tables[tab],
    fields = schema(tab);
  const { data, error } = await supabaseClient
    .from(meta.table)
    .select("*")
    .order("created_at", { ascending: false });
  if (error) {
    toast(error.message);
    return;
  }
  const hasImage = tab === "gallery" || tab === "reviews";
  const imageHead = hasImage ? "<th>Image</th>" : "";
  const imageCell = (row) =>
    hasImage
      ? `<td>${row.image_url || row.customer_image ? `<img class="table-thumb" src="${esc(row.image_url || row.customer_image)}" alt="${esc(row.design_name || row.customer_name)}">` : '<span class="note">No image</span>'}</td>`
      : "";
  const enquiry = (row) =>
    tab === "gallery"
      ? `<a class="small whatsapp-action" href="${waUrl(row)}" target="_blank" rel="noopener">WhatsApp enquiry</a>`
      : "";
  const cellValue = (row, field) =>
    field.type === "checkbox" ? (row[field.k] ? "Yes" : "No") : row[field.k];
  $("#" + tab).innerHTML =
    `<div class="panel"><div class="toolbar"><div><h2>${meta.title}</h2><div class="note">${tab === "gallery" ? "Add, edit, delete, upload images, and forward design enquiries to WhatsApp." : "Add, edit, or delete customer reviews."}</div></div><button type="button" class="btn" data-add-item="${tab}">+ Add ${tab === "gallery" ? "Design" : "Review"}</button></div><div id="editor"></div><div style="overflow:auto"><table class="table"><thead><tr>${imageHead}${fields.map((f) => `<th>${f.l}</th>`).join("")}<th>Actions</th></tr></thead><tbody>${(data || []).map((row) => `<tr>${imageCell(row)}${fields.map((f) => `<td>${esc(cellValue(row, f))}</td>`).join("")}<td><div class="actions">${enquiry(row)}<button type="button" class="small" data-edit="${row.id}">Edit</button><button type="button" class="small danger" data-delete="${row.id}">Delete</button></div></td></tr>`).join("")}</tbody></table></div></div>`;
  document.querySelectorAll("[data-edit]").forEach(
    (b) =>
      (b.onclick = () =>
        editor(
          tab,
          (data || []).find((x) => x.id == b.dataset.edit),
        )),
  );
  document
    .querySelectorAll("[data-delete]")
    .forEach((b) => (b.onclick = () => del(tab, b.dataset.delete)));
}
function waUrl(row) {
  const message = encodeURIComponent(
    `Hello Rytham Fashions, I would like to enquire about ${row.design_name || "this design"}${row.price ? ` priced at Rs. ${row.price}` : ""}.`,
  );
  return `https://wa.me/919626397113?text=${message}`;
}
function convertToWebp(file, quality = 0.82) {
  return new Promise((resolve, reject) => {
    const image = new Image();
    const objectUrl = URL.createObjectURL(file);
    image.onload = () => {
      URL.revokeObjectURL(objectUrl);
      const canvas = document.createElement("canvas");
      canvas.width = image.naturalWidth;
      canvas.height = image.naturalHeight;
      canvas.getContext("2d").drawImage(image, 0, 0);
      canvas.toBlob(
        (blob) =>
          blob ? resolve(blob) : reject(new Error("WebP conversion failed")),
        "image/webp",
        quality,
      );
    };
    image.onerror = () => {
      URL.revokeObjectURL(objectUrl);
      reject(new Error("This image format cannot be converted by the browser"));
    };
    image.src = objectUrl;
  });
}
function editor(tab, row) {
  const fields = schema(tab);
  editing = row;
  const imageField =
    tab === "gallery" || tab === "reviews" || tab === "services";
  const imageLabel =
    tab === "gallery"
      ? "Design Image"
      : tab === "reviews"
        ? "Customer Image"
        : "Service Image";
  const galleryUrlField =
    tab === "gallery"
      ? `<div class="form-group full"><label for="imageUrl">Online image URL</label><input id="imageUrl" type="url" value="${esc(row?.image_url ?? "")}" placeholder="https://images.unsplash.com/..."><span class="note">Use an Unsplash image URL, or select a file below.</span></div>`
      : "";
  const html = `<div class="panel" style="margin-bottom:15px"><h2>${row ? "Edit" : "Add"} ${tab === "gallery" ? "Design" : tab === "reviews" ? "Review" : "Service"}</h2><div class="form">${fields.map((f) => `<div class="form-group ${f.type === "textarea" ? "full" : ""}"><label for="f_${f.k}">${f.l}</label>${f.type === "textarea" ? `<textarea id="f_${f.k}">${esc(row?.[f.k] ?? "")}</textarea>` : f.type === "select" ? `<select id="f_${f.k}" ${f.req ? "required" : ""}>${[...new Set([...(f.options || []), row?.[f.k]].filter(Boolean))].map((option) => `<option value="${esc(option)}" ${row?.[f.k] === option ? "selected" : ""}>${esc(option)}</option>`).join("")}</select>` : f.type === "checkbox" ? `<input id="f_${f.k}" type="checkbox" ${row?.[f.k] ? "checked" : ""}>` : `<input id="f_${f.k}" type="${f.type}" min="${f.k === "rating" ? "1" : f.k === "price" ? "0" : ""}" max="${f.k === "rating" ? "5" : ""}" step="${f.k === "rating" ? "1" : "any"}" value="${esc(row?.[f.k] ?? "")}" ${f.req ? "required" : ""}>`}</div>`).join("")}${galleryUrlField}${imageField ? `<div class="form-group full"><label for="imageFile">${imageLabel}${tab === "gallery" && !row ? " (required)" : ""}</label><input id="imageFile" type="file" accept="image/*"><span class="note">${row?.[tab === "gallery" ? "image_url" : tab === "reviews" ? "customer_image" : "image_url"] ? "Current image will remain if no replacement is selected." : `Upload to ${tab === "services" ? "service-images" : "gallery-images"}.`}</span></div>` : ""}<div id="editorStatus" class="editor-status" role="status" aria-live="polite"></div><div class="form-actions"><button type="button" class="btn" id="saveBtn">Save Changes</button><button type="button" class="small" id="cancelBtn">Cancel</button></div></div></div>`;
  $("#editor").innerHTML = html;
  $("#cancelBtn").onclick = () => {
    $("#editor").innerHTML = "";
    editing = null;
  };
  $("#saveBtn").onclick = () => save(tab);
}
async function save(tab) {
  const button = $("#saveBtn"),
    status = $("#editorStatus");
  if (button) button.disabled = true;
  if (status) status.textContent = "Saving...";
  try {
    const {
      data: { session },
    } = await supabaseClient.auth.getSession();
    if (!session)
      throw new Error("Your admin session has expired. Please sign in again.");
    const fields = schema(tab),
      payload = {};
    for (const f of fields) {
      const input = $(`#f_${f.k}`),
        v = f.type === "checkbox" ? input.checked : input.value.trim();
      if (f.req && !v) {
        toast(`${f.l} is required`);
        if (status) status.textContent = `${f.l} is required`;
        return;
      }
      if (f.k === "price" && Number(v) < 0) {
        toast("Price cannot be negative");
        if (status) status.textContent = "Price cannot be negative";
        return;
      }
      if (
        f.k === "rating" &&
        (!Number.isInteger(Number(v)) || Number(v) < 1 || Number(v) > 5)
      ) {
        toast("Rating must be an integer from 1 to 5");
        if (status)
          status.textContent = "Rating must be an integer from 1 to 5";
        return;
      }
      payload[f.k] = f.type === "number" ? (v ? Number(v) : 0) : v;
    }
    if (tab === "gallery" || tab === "reviews" || tab === "services") {
      const file = $("#imageFile")?.files[0];
      const imageUrl = tab === "gallery" ? $("#imageUrl")?.value.trim() : "";
      if (tab === "gallery" && !editing && !file && !imageUrl) {
        toast("Design image is required");
        if (status) status.textContent = "Design image is required";
        return;
      }
      if (tab === "gallery" && imageUrl) payload.image_url = imageUrl;
      if (file) {
        const bucket = tab === "services" ? "service-images" : "gallery-images";
        const uploadFile = tab === "gallery" ? await convertToWebp(file) : file;
        const extension =
          tab === "gallery" ? "webp" : file.name.split(".").pop().toLowerCase();
        const path = `${Date.now()}-${crypto.randomUUID()}.${extension}`;
        const up = await supabaseClient.storage
          .from(bucket)
          .upload(path, uploadFile, {
            upsert: false,
            contentType: tab === "gallery" ? "image/webp" : file.type,
          });
        if (up.error) throw up.error;
        const url = supabaseClient.storage.from(bucket).getPublicUrl(path)
          .data.publicUrl;
        if (tab === "gallery" || tab === "services") payload.image_url = url;
        else payload.customer_image = url;
      }
    }
    const query = supabaseClient.from(tables[tab].table);
    const res = editing
      ? await query.update(payload).eq("id", editing.id).select().single()
      : await query.insert(payload).select().single();
    if (res.error) throw res.error;
    toast(`${tab === "reviews" ? "Review" : "Design"} saved successfully`);
    editing = null;
    await crud(tab);
  } catch (error) {
    console.error(error);
    const detail = [error.message, error.details, error.hint, error.code]
      .filter(Boolean)
      .join(" | ");
    const message =
      detail || "Check Supabase permissions and the reviews table schema.";
    if (status) status.textContent = `Unable to save: ${message}`;
    toast(
      `Unable to save ${tab === "reviews" ? "review" : "design"}: ${message}`,
    );
  } finally {
    if (button) button.disabled = false;
  }
}
async function del(tab, id) {
  if (!confirm("Delete this item?")) return;
  const { error } = await supabaseClient
    .from(tables[tab].table)
    .delete()
    .eq("id", id);
  if (error) toast(error.message);
  else {
    toast("Deleted");
    crud(tab);
  }
}
async function settings() {
  const { data } = await supabaseClient
    .from("business_settings")
    .select("*")
    .limit(1)
    .maybeSingle();
  const s = data || {};
  $("#settings").innerHTML =
    `<div class="panel"><h2>Business Settings</h2><p class="note">These values control the public contact and business information.</p><div class="form"><div class="form-group"><label>Business name</label><input id="set_business_name" value="${esc(s.business_name || "Rytham Fashions")}"></div><div class="form-group"><label>Phone</label><input id="set_phone" value="${esc(s.phone || "")}"></div><div class="form-group"><label>WhatsApp number</label><input id="set_whatsapp" value="${esc(s.whatsapp || "")}"></div><div class="form-group"><label>Instagram URL</label><input id="set_instagram" value="${esc(s.instagram || "https://www.instagram.com/rytham_fashions_porayar")}"></div><div class="form-group full"><label>Address</label><input id="set_address" value="${esc(s.address || "JP Kavya Complex, Veerapillai St, Kattucherry")}"></div><div class="form-group full"><label>Google Maps URL</label><input id="set_google_maps" value="${esc(s.google_maps || "https://maps.app.goo.gl/B3PiJ8JTEbUQyAt57")}"></div><div class="form-group full"><label>Opening hours</label><textarea id="set_opening_hours">${esc(s.opening_hours || "")}</textarea></div><div class="form-actions"><button class="btn" id="saveSettings">Save settings</button></div></div></div>`;
  $("#saveSettings").onclick = saveSettings;
}
async function saveSettings() {
  const payload = {
    business_name: $("#set_business_name").value,
    phone: $("#set_phone").value,
    whatsapp: $("#set_whatsapp").value,
    instagram: $("#set_instagram").value,
    address: $("#set_address").value,
    google_maps: $("#set_google_maps").value,
    opening_hours: $("#set_opening_hours").value,
  };
  const { data } = await supabaseClient
    .from("business_settings")
    .select("id")
    .limit(1)
    .maybeSingle();
  const res = data
    ? await supabaseClient
        .from("business_settings")
        .update(payload)
        .eq("id", data.id)
    : await supabaseClient.from("business_settings").insert(payload);
  if (res.error) toast(res.error.message);
  else toast("Settings saved");
}
async function enquiries() {
  const { data, error } = await supabaseClient
    .from("enquiries")
    .select("*")
    .order("created_at", { ascending: false });
  if (error) {
    toast(error.message);
    return;
  }
  $("#enquiries").innerHTML =
    `<div class="panel"><div class="toolbar"><h2>Enquiries</h2></div><div style="overflow:auto"><table class="table"><thead><tr><th>Date</th><th>Customer</th><th>Phone</th><th>Message</th><th>Source</th></tr></thead><tbody>${(data || []).map((x) => `<tr><td>${new Date(x.created_at).toLocaleString("en-IN")}</td><td>${esc(x.customer_name)}</td><td>${esc(x.phone)}</td><td>${esc(x.message)}</td><td>${esc(x.source)}</td></tr>`).join("")}</tbody></table></div></div>`;
}
function toast(m) {
  const x = $("#toast");
  x.textContent = m;
  x.style.display = "block";
  setTimeout(() => (x.style.display = "none"), 2500);
}
init();
document.addEventListener("click", (event) => {
  const add = event.target.closest('[data-add-item="reviews"]');
  if (add)
    setTimeout(
      () =>
        document
          .querySelector(".tab:not(.hidden) #imageFile")
          ?.closest(".form-group")
          ?.remove(),
      0,
    );
});
