const $ = (s) => document.querySelector(s);
const esc = (v) =>
  String(v ?? "").replace(
    /[&<>"']/g,
    (c) =>
      ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[
        c
      ],
  );
let gallery = [],
  activeCategory = "All",
  visibleLimit = 8;
const categoryOptions = [
  "All",
  "Simple Aari Works (₹1,000–₹1,500)",
  "Semi heavy aari work (₹1,500–₹2,500)",
  "Bridal Aari Works (₹3,000–₹5,000)",
  "Bridal Aari Works (₹5,000–₹8,000)",
  "Heavy Aari Works (Above ₹8,000)",
  "Machine Embroidery Work (Price on request)",
  "Pattern Blouse (Price on request)",
];
const starterServices = [
  {
    name: "Aari & Embroidery",
    description: "Intricate designs, beautifully crafted",
    image_url: "assets/gallery-1.jpg",
  },
  {
    name: "Blouse Stitching",
    description: "All types of pattern blouses",
    image_url: "assets/gallery-2.jpg",
  },
  {
    name: "Bridal Blouse",
    description: "Make your special day more beautiful",
    image_url: "assets/gallery-3.jpg",
  },
  {
    name: "Ladies Tailoring",
    description: "Sarees, dresses and custom stitching",
    image_url: "assets/gallery-4.jpg",
  },
  {
    name: "Alterations",
    description: "Perfect fit, every time",
    image_url: "assets/gallery-5.jpg",
  },
  {
    name: "Kids Dress",
    description: "Comfortable custom outfits for little ones",
    image_url: "assets/gallery-6.jpg",
  },
];
const settingsDefault = {
  business_name: "Rytham Fashions",
  phone: "+91 9626397113",
  whatsapp: "+91 9626397113",
  instagram: "https://www.instagram.com/rytham_fashions_porayar",
  address: "JP Kavya Complex, Veerapillai St, Porayar",
  google_maps: "https://maps.app.goo.gl/B3PiJ8JTEbUQyAt57",
};
const footerLocation = "JP Kavya Complex, Veerapillai St, Porayar";
let enquiryNumber = settingsDefault.whatsapp;
function waUrl(number) {
  const n = (number || "").replace(/\D/g, "");
  const message = encodeURIComponent(
    "Hello Rytham Fashions, I would like to enquire about your services.",
  );
  return n ? `https://wa.me/${n}?text=${message}` : "#";
}
async function loadReviews() {
  const { data, error } = await supabaseClient
    .from("reviews")
    .select("*")
    .order("created_at", { ascending: false });
  if (error) throw error;
  renderReviews(data || []);
}
async function load() {
  const [s, sv, g] = await Promise.all([
    supabaseClient.from("business_settings").select("*").limit(1).maybeSingle(),
    supabaseClient
      .from("services")
      .select("*")
      .order("created_at", { ascending: false }),
    supabaseClient
      .from("gallery")
      .select("*")
      .order("created_at", { ascending: false }),
  ]);
  const settings = { ...settingsDefault, ...(s.data || {}) };
  applySettings(settings);
  renderServices(sv.data?.length ? sv.data : starterServices);
  gallery = g.data || [];
  restoreFilters();
  renderCategories();
  $("#categoryFilter").value = activeCategory;
  renderGallery();
  await loadReviews();
  supabaseClient
    .channel("public-reviews")
    .on(
      "postgres_changes",
      { event: "*", schema: "public", table: "reviews" },
      () => loadReviews().catch(console.error),
    )
    .subscribe();
}
function applySettings(s) {
  $("#brandName").textContent = s.business_name || "Rytham Fashions";
  $("#footerAddress").innerHTML =
    `<i class="fa-solid fa-location-dot" aria-hidden="true"></i> ${footerLocation}`;
  $("#footerPhone").innerHTML =
    `<i class="fa-solid fa-phone" aria-hidden="true"></i> ${esc(s.phone || settingsDefault.phone)}`;
  enquiryNumber = s.whatsapp || settingsDefault.whatsapp;
  const whatsapp = waUrl(enquiryNumber);
  $("#heroWhatsApp").href = whatsapp;
  $("#floatingWhatsApp").href = whatsapp;
  $("#navWhatsApp").href = whatsapp;
  $("#footerWhatsApp").href = whatsapp;
  const footerWhatsapp = $('.footer-social-icons a[aria-label="WhatsApp"]');
  if (footerWhatsapp) footerWhatsapp.href = whatsapp;
}
function renderServices(items) {
  $("#servicesGrid").innerHTML = items.length
    ? items
        .map(
          (x) =>
            `<article class="service-card"><div class="service-img">${x.image_url ? `<img src="${esc(x.image_url)}" alt="${esc(x.name)}">` : "✦"}</div><div class="service-body"><span class="eyebrow">SERVICE</span><h3>${esc(x.name)}</h3><p class="muted">${esc(x.description)}</p>${x.starting_price ? `<b>From ₹${Number(x.starting_price).toLocaleString("en-IN")}</b>` : ""}</div></article>`,
        )
        .join("")
    : '<div class="empty">Services will appear here once added from Admin.</div>';
}
function designWaUrl(x) {
  const price = Number(x.price || 0);
  const shownPrice = x.price_on_request
    ? "Price on request"
    : `₹${price.toLocaleString("en-IN")}`;
  const message = encodeURIComponent(
    `Hello Rytham Fashions, I would like to enquire about this design.\n\nDesign: ${x.design_name || "Design"}\nCategory: ${x.category || "Not specified"}\nPrice: ${shownPrice}\n\nPlease share more details.`,
  );
  const n = (enquiryNumber || "").replace(/\D/g, "");
  return n ? `https://wa.me/${n}?text=${message}` : "#";
}
function renderCategories() {
  $("#categoryFilter").innerHTML = categoryOptions
    .map(
      (c) =>
        `<option value="${esc(c)}">${c === "All" ? "All Categories" : esc(c)}</option>`,
    )
    .join("");
}
function filteredGallery() {
  let items = gallery.filter(
    (x) => activeCategory === "All" || x.category === activeCategory,
  );
  const priceFilter = $("#priceFilter").value;
  items = items.filter((x) => {
    const price = Number(x.price || 0);
    if (priceFilter === "1000to1500") return price >= 1000 && price <= 1500;
    if (priceFilter === "1500to2500") return price > 1500 && price <= 2500;
    if (priceFilter === "2500to3000") return price > 2500 && price <= 3000;
    if (priceFilter === "3000to5000") return price >= 3000 && price <= 5000;
    if (priceFilter === "5000to8000") return price > 5000 && price <= 8000;
    if (priceFilter === "over8000") return price > 8000;
    if (priceFilter === "onrequest") return Boolean(x.price_on_request);
    return true;
  });
  const sort = $("#sortPrice").value;
  if (sort === "low")
    items.sort((x, y) => Number(x.price || 0) - Number(y.price || 0));
  if (sort === "high")
    items.sort((x, y) => Number(y.price || 0) - Number(x.price || 0));
  return items;
}
function renderGallery() {
  const items = filteredGallery();
  const shown = items.slice(0, visibleLimit);
  const displayPrice = (x) =>
    x.price_on_request
      ? "Price on request"
      : `₹${Number(x.price || 0).toLocaleString("en-IN")}`;
  $("#galleryGrid").innerHTML = shown.length
    ? shown
        .map(
          (x) =>
            `<article class="gallery-card"><div class="gallery-img">${x.image_url ? `<img src="${esc(x.image_url)}" alt="${esc(x.design_name)}">` : '<div class="empty">Image unavailable</div>'}<span class="price-tag">${displayPrice(x)}</span></div><div class="gallery-info"><h3>${esc(x.design_name)}</h3><span class="muted design-price">${displayPrice(x)}</span><p class="muted">${esc(x.description)}</p><a class="design-enquiry" href="${designWaUrl(x)}" target="_blank" rel="noopener" onclick="if(!enquiryNumber){event.preventDefault();alert('WhatsApp is not configured yet. Please contact the studio directly.');}"><i class="fa-brands fa-whatsapp" aria-hidden="true"></i> Enquire on WhatsApp</a></div></article>`,
        )
        .join("")
    : '<div class="empty">No designs match your selected filters.</div>';
  const more = $("#viewMoreDesigns");
  more.hidden = items.length <= visibleLimit;
  more.disabled = items.length <= visibleLimit;
}
function updateFilterUrl() {
  const params = new URLSearchParams();
  if (activeCategory !== "All") params.set("category", activeCategory);
  if ($("#priceFilter").value !== "all")
    params.set("price", $("#priceFilter").value);
  const query = params.toString();
  history.replaceState(null, "", `${location.pathname}${query ? `?${query}` : ""}${location.hash}`);
}
function restoreFilters() {
  const params = new URLSearchParams(location.search);
  activeCategory = params.get("category") || "All";
  const price = params.get("price");
  if (price && $("#priceFilter").querySelector(`option[value="${CSS.escape(price)}"]`))
    $("#priceFilter").value = price;
}
async function shareFilters() {
  updateFilterUrl();
  const url = location.href;
  const label = activeCategory === "All" ? "these designs" : `${activeCategory} designs`;
  try {
    if (navigator.share)
      await navigator.share({ title: "Rytham Fashions designs", text: `Please view ${label}.`, url });
    else await navigator.clipboard.writeText(url);
    alert(navigator.share ? "Filter link shared." : "Filter link copied.");
  } catch (error) {
    if (error.name !== "AbortError") alert(`Copy this link to share the selected filters: ${url}`);
  }
}
function renderReviews(items) {
  $("#reviewsGrid").innerHTML = items.length
    ? items
        .map(
          (x) =>
            `<article class="review">${x.customer_image ? `<img class="review-image" src="${esc(x.customer_image)}" alt="${esc(x.customer_name)}">` : ""}<div class="stars">${"★".repeat(Math.max(0, Math.min(5, Number(x.rating) || 0)))}${"☆".repeat(5 - Math.max(0, Math.min(5, Number(x.rating) || 0)))}</div><p>“${esc(x.review_text)}”</p><b>${esc(x.customer_name)}</b></article>`,
        )
        .join("")
    : '<div class="empty">No customer reviews yet.</div>';
}
$("#categoryFilter").onchange = () => {
  activeCategory = $("#categoryFilter").value;
  visibleLimit = 8;
  updateFilterUrl();
  renderGallery();
};
$("#priceFilter").onchange = () => {
  visibleLimit = 8;
  updateFilterUrl();
  renderGallery();
};
$("#sortPrice").onchange = () => {
  visibleLimit = 8;
  renderGallery();
};
$("#viewMoreDesigns").onclick = () => {
  visibleLimit += 8;
  renderGallery();
};
$("#shareFilters").onclick = shareFilters;
$("#menuBtn").onclick = () => $("#mainNav").classList.toggle("open");
$("#year").textContent = new Date().getFullYear();
load().catch((e) => {
  console.error(e);
  document
    .querySelectorAll(".loading")
    .forEach(
      (x) =>
        (x.textContent =
          "Unable to load content. Check Supabase configuration."),
    );
});
document.body.insertAdjacentHTML(
  "beforeend",
  '<a class="float-instagram" id="floatingInstagram" href="https://www.instagram.com/rytham_fashions_porayar" target="_blank" rel="noopener" aria-label="Instagram"><i class="fa-brands fa-instagram" aria-hidden="true"></i></a>',
);
document.querySelector(".footer-bottom").innerHTML =
  '<div class="footer-copy"><div class="footer-copyright">© 2026 Rytham Fashions. ALL RIGHTS RESERVED.</div><div class="footer-credit">Designed &amp; Developed by <a href="https://raventrixtechnologies.netlify.app/" target="_blank" rel="noopener">Raventrix Technologies</a></div></div><div class="footer-social-icons"><a href="' +
  waUrl(enquiryNumber) +
  '" target="_blank" rel="noopener" aria-label="WhatsApp"><i class="fa-brands fa-whatsapp" aria-hidden="true"></i></a><a href="https://www.instagram.com/rytham_fashions_porayar" target="_blank" rel="noopener" aria-label="Instagram"><i class="fa-brands fa-instagram" aria-hidden="true"></i></a><a href="#" aria-label="Facebook"><i class="fa-brands fa-facebook-f" aria-hidden="true"></i></a></div>';
