<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Pemantau Data Farm - Tampilan Diperbaiki</title>
  <script src="https://cdn.tailwindcss.com"></script>
  <style>
    * { scrollbar-width: thin; scrollbar-color: #475569 #1e293b; }
    ::-webkit-scrollbar { width: 6px; }
    ::-webkit-scrollbar-track { background: #1e293b; border-radius: 999px; }
    ::-webkit-scrollbar-thumb { background: #475569; border-radius: 999px; }

    .panel { transition: all 0.25s ease; border-radius: 1rem; border: 1px solid #334155; background: #1e293b; }
    .panel-aktif { background: rgba(16,185,129,0.15); transform: scale(1.005); }
    .baris-baru { animation: masuk 0.4s ease; }
    @keyframes masuk { from{opacity:0;transform:translateX(-8px)} to{opacity:1;transform:translateX(0)} }

    .angka-naik { color:#4ade80; font-weight:bold; position:relative; }
    .tanda-perubahan {
      position:absolute; left:-28px; font-size:0.75rem; white-space:nowrap;
      animation: melayang 0.8s ease-out forwards; pointer-events: none;
    }
    .tanda-tambah { color:#fbbf24; }
    .tanda-ganti { color:#60a5fa; }
    @keyframes melayang { 0%{opacity:1;transform:translateY(0)} 100%{opacity:0;transform:translateY(-16px)} }

    .kotak-uang { transition: 0.3s; }
    .berubah-uang { animation:kilau 0.5s ease; background:rgba(234,179,8,0.15); }
    @keyframes kilau { 0%,100%{box-shadow:none} 50%{box-shadow:0 0 10px rgba(234,179,8,0.3)} }

    /* ✅ PANEL LEBIH PANJANG KE BAWAH */
    .gulir-panjang { max-height: 420px; overflow-y: auto; scroll-behavior: smooth; }
    .log-panjang { max-height: 280px; overflow-y: auto; scroll-behavior: smooth; }
  </style>
</head>
<body class="bg-slate-900 text-white min-h-screen p-3 md:p-4">
  <div class="w-full max-w-3xl mx-auto">
    <h1 class="text-2xl font-bold text-center mb-5 text-emerald-400">📡 Pemantauan Langsung • JSON</h1>

    <!-- Info Atas -->
    <div class="grid grid-cols-2 gap-3 mb-4">
      <div class="panel p-3">
        <div class="text-slate-400 text-sm">🕒 Waktu Terima</div>
        <div id="waktu" class="font-semibold text-lg">—</div>
      </div>
      <div class="panel p-3">
        <div class="text-slate-400 text-sm">📶 Sumber</div>
        <div id="sumber" class="font-semibold text-emerald-300">—</div>
      </div>
    </div>

    <!-- Ringkasan Cepat -->
    <div class="grid grid-cols-3 gap-3 mb-4">
      <div id="kotakUang" class="kotak-uang panel p-3 text-center">
        <div class="text-slate-400 text-sm">💰 Uang</div>
        <div id="nilaiUang" class="font-bold text-lg text-yellow-400">—</div>
      </div>
      <div class="panel p-3 text-center">
        <div class="text-slate-400 text-sm">📦 Total Berat</div>
        <div id="nilaiBerat" class="font-bold text-lg text-sky-400">—</div>
      </div>
      <div class="panel p-3 text-center">
        <div class="text-slate-400 text-sm">🧾 Jumlah Barang</div>
        <div id="nilaiJumlah" class="font-bold text-lg text-sky-400">—</div>
      </div>
    </div>

    <!-- 🎒 PANEL BARANG BIASA - LEBIH TINGGI -->
    <div id="panelBarang" class="panel p-4 mb-4">
      <h3 class="text-sky-400 font-semibold mb-2">🎒 Barang di Tas</h3>
      <div id="isiBarang" class="gulir-panjang text-sm pl-3">
        <span class="text-amber-400">Menunggu data...</span>
      </div>
    </div>

    <!-- 🌾 PANEL HASIL PANEN - RIWAYAT SAMPAI 20 BARIS -->
    <div id="panelPanen" class="panel p-4">
      <h3 class="text-sky-400 font-semibold mb-2">🌾 Riwayat Hasil Panen & Mutasi</h3>
      <div id="isiPanen" class="log-panjang text-sm pl-3 text-emerald-300">
        <span class="text-slate-500">— Belum ada hasil —</span>
      </div>
    </div>

    <p class="text-center text-slate-500 text-sm mt-4">🔄 Memperbarui setiap 2 detik</p>
  </div>

  <script>
    let simpan = { uang:"", barang:{}, panen:{} };
    let riwayatPanen = []; // ✅ Simpan riwayat penuh
    const MAKS_LOG = 20; // ✅ Batas maksimal 20 baris
    let teksLama = "";

    function tandai(id) {
      const el = document.getElementById(id);
      el.classList.add("panel-aktif");
      setTimeout(()=>el.classList.remove("panel-aktif"),400);
    }

    // ✅ TAMPILKAN PERUBAHAN: SEBELUM → SESUDAH
    function cekPerubahan(nama, jmlBaru, jenis) {
      const lama = simpan[jenis][nama] || 0;
      if (jmlBaru === lama) return jmlBaru;

      // Ada perubahan
      if (jmlBaru > lama) {
        const selisih = jmlBaru - lama;
        return `<span class="angka-naik">${jmlBaru}</span><span class="tanda-perubahan tanda-tambah">+${selisih} (dari ${lama})</span>`;
      } else {
        return `<span class="text-red-400">${jmlBaru}</span><span class="tanda-perubahan tanda-ganti">↓ ${lama} → ${jmlBaru}</span>`;
      }
    }

    async function muatData() {
      try {
        const res = await fetch("/api/webhook", {cache:"no-store"});
        if (!res.ok) throw new Error("Putus");
        const d = await res.json();
        const data = d.data || {};
        const teksBaru = JSON.stringify(data);

        if (teksBaru !== teksLama) {
          teksLama = teksBaru;

          // Info Umum
          document.getElementById("waktu").textContent = d.waktu || "—";
          document.getElementById("sumber").textContent = d.sumber || "—";
          const uangBaru = data.uangFormat || "0";
          if (uangBaru !== simpan.uang) {
            simpan.uang = uangBaru;
            document.getElementById("kotakUang").classList.add("berubah-uang");
            setTimeout(()=>document.getElementById("kotakUang").classList.remove("berubah-uang"),600);
          }
          document.getElementById("nilaiUang").textContent = uangBaru;
          document.getElementById("nilaiBerat").textContent = `${data.totalBeratFormat||"0"} KG`;
          document.getElementById("nilaiJumlah").textContent = `${data.totalItem||0} buah`;

          // 🎒 Tampilkan Barang Biasa - Tampilkan Sebelum/Sesudah
          let htmlBarang = "";
          const barangBaru = {};
          if (data.barang && Object.keys(data.barang).length>0) {
            const urut = Object.entries(data.barang).sort((a,b)=>b[1]-a[1]);
            for (const [nama, jml] of urut) {
              barangBaru[nama] = jml;
              const tampil = cekPerubahan(nama, jml, "barang");
              htmlBarang += `<div class="mb-2 relative">• ${nama} x${tampil}</div>`;
            }
          } else htmlBarang = "<span class='text-slate-500'>— Kosong —</span>";
          simpan.barang = barangBaru;
          document.getElementById("isiBarang").innerHTML = htmlBarang;
          tandai("panelBarang");
          setTimeout(()=>document.getElementById("isiBarang").scrollTop=9999,50);

          // 🌾 TAMBAH KE RIWAYAT PANEN SATU PER SATU
          if (data.panen && Object.keys(data.panen).length>0) {
            const urut = Object.entries(data.panen).sort((a,b)=>b[1].beratTotal - a[1].beratTotal);
            let adaBaru = false;
            const sekarang = new Date().toLocaleTimeString("id-ID");

            for (const [nama, info] of urut) {
              const lama = simpan.panen[nama] || 0;
              if (info.jumlah > lama) {
                // ✅ MASUKKAN BARIS BARU KE RIWAYAT
                const selisih = info.jumlah - lama;
                const rata = (info.beratTotal / info.jumlah).toFixed(2);
                riwayatPanen.push({
                  waktu: sekarang,
                  teks: `• ${nama} → ${rata} KG | ${lama} → ${info.jumlah} (+${selisih})`
                });
                adaBaru = true;
              }
              simpan.panen[nama] = info.jumlah;
            }

            // ✅ SIMPAN HANYA 20 TERAKHIR
            if (riwayatPanen.length > MAKS_LOG) {
              riwayatPanen = riwayatPanen.slice(-MAKS_LOG);
            }

            // ✅ TAMPILKAN DARI PALING BARU DI BAWAH
            let htmlLog = "";
            riwayatPanen.forEach((item, indeks) => {
              const kelas = adaBaru && indeks === riwayatPanen.length - 1 ? "baris-baru" : "";
              htmlLog += `<div class="py-2 border-b border-slate-700/50 ${kelas}">
                <span class="text-slate-400 text-xs">${item.waktu}</span> ${item.teks}
              </div>`;
            });

            document.getElementById("isiPanen").innerHTML = htmlLog;
            if (adaBaru) tandai("panelPanen");
            setTimeout(()=>document.getElementById("isiPanen").scrollTop=9999,50);
          }
        }

      } catch (e) {
        document.getElementById("isiBarang").innerHTML = '<span class="text-red-400">❌ Terputus — cek Termux</span>';
      }
    }

    muatData();
    setInterval(muatData, 2000);
  </script>
</body>
</html>
