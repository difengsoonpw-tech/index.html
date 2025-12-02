// script.js that fetches products.json at runtime and builds the UI

fetch('products.json').then(r => r.json()).then(PRODUCTS => {
    const container = document.getElementById("menuContainer");
    Object.keys(PRODUCTS).forEach(category => {
        let catDiv = document.createElement("div");
        catDiv.className = "category";
        catDiv.innerHTML = `<div class="category-title">${category}</div>`;
        PRODUCTS[category].forEach(item => {
            let card = document.createElement("div");
            card.className = "item-card";
            let meta = "";
            if (item.addon) meta += `<div class="item-meta">${item.addon}</div>`;
            card.innerHTML = `
                <div>
                    <div class="item-name">${item.name}</div>
                    ${meta}
                </div>
                <div class="controls">
                    ${item.choice ? `<select class="qty-box choice">${item.choice.split('/').map(c=>`<option>${c.trim()}</option>`).join('')}</select>` : ''}
                    <input type="number" class="qty-box qty" placeholder="Qty" min="1">
                    <button class="add-btn">Add</button>
                </div>
            `;
            card.querySelector(".add-btn").addEventListener("click", () => {
                let qtyInput = card.querySelector(".qty");
                let qty = qtyInput.value;
                if (!qty || Number(qty) <= 0) return;
                let choiceEl = card.querySelector(".choice");
                let choice = choiceEl ? choiceEl.value : "";
                CART.push({ item: item.name, qty: Number(qty), choice });
                updateSummaryBar();
                qtyInput.value = "";
            });
            catDiv.appendChild(card);
        });
        container.appendChild(catDiv);
    });
}).catch(err => {
    console.error('Failed to load products.json', err);
    document.getElementById('menuContainer').innerHTML = '<div style="padding:20px;color:#900;">Failed to load product list. Check products.json formatting.</div>';
});

// CART and UI actions
let CART = [];
function updateSummaryBar() {
    document.getElementById("cartCount").innerText = CART.reduce((s,i)=>s+i.qty,0);
}
function openSummary() {
    let output = "";
    CART.forEach(c=> {
        output += `• ${c.item}${c.choice ? " ("+c.choice+")" : ""} x ${c.qty}\n`;
    });
    document.getElementById("summaryText").value = output || "No items selected.";
    document.getElementById("summaryPopup").style.display = "flex";
}
function closeSummary(){ document.getElementById("summaryPopup").style.display = "none"; }
function sendWhatsApp(){ let msg = encodeURIComponent(document.getElementById("summaryText").value); window.open("https://wa.me/?text="+msg, "_blank"); }
function copyText(){ navigator.clipboard.writeText(document.getElementById("summaryText").value).then(()=>{ alert('Copied summary to clipboard'); }); }
updateSummaryBar();
