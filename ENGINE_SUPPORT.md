# Engine Support - Sun-Sword

Sun-sword sekarang mendukung generate ke specific Rails Engine untuk aplikasi modular.

## Fitur

- ✅ Generate frontend ke engine tertentu
- ✅ Generate scaffold ke engine tertentu
- ✅ Ambil structure file dari engine lain
- ✅ Multiple engine support
- ✅ Auto-detect engine path (engines/, components/, gems/)

---

## Struktur Engine yang Didukung

Sun-sword akan otomatis mendeteksi engine di lokasi berikut:

```
project/
├── engines/
│   ├── admin/          # Engine admin
│   ├── api/            # Engine api
│   └── ...
├── components/
│   └── blog/           # Component engine
├── gems/
│   └── core/           # Gem engine
└── app/                # Main app (default)
```

**Syarat**: Setiap engine harus memiliki `[engine_name].gemspec` file.

---

## Usage

### 1. Frontend Generator dengan Engine

#### Generate frontend ke main app (default):
```bash
rails g sun_sword:frontend --setup
```

#### Generate frontend ke specific engine:
```bash
# Generate ke engine 'admin'
rails g sun_sword:frontend --setup --engine=admin

# Generate ke engine 'api'
rails g sun_sword:frontend --setup --engine=api
```

**Hasil:**
- File akan digenerate ke `engines/admin/app/` bukan `app/`
- Views, controllers, helpers ada di dalam engine

---

### 2. Scaffold Generator dengan Engine

#### Generate scaffold ke main app (default):
```bash
rails g sun_sword:scaffold user
rails g sun_sword:scaffold product scope:dashboard
```

#### Generate scaffold ke specific engine:
```bash
# Generate ke engine 'admin', ambil structure dari main app
rails g sun_sword:scaffold user --engine=admin

# Generate ke engine 'admin', ambil structure dari engine 'admin'
rails g sun_sword:scaffold user --engine=admin --engine_structure=admin

# Generate ke engine 'api', ambil structure dari engine 'core'
rails g sun_sword:scaffold product --engine=api --engine_structure=core
```

---

## Options Detail

### Frontend Generator

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `--setup` | boolean | false | **Required**. Setup frontend structure |
| `--engine` | string | nil | Target engine name untuk generate |

### Scaffold Generator

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `--engine` | string | nil | Target engine untuk generate files |
| `--engine_structure` | string | nil | Source engine untuk ambil structure file |

**Note**: Jika `--engine_structure` tidak diset, akan fallback ke `--engine`.

---

## Contoh Kasus Nyata

### Kasus 1: Multi-tenant dengan Engine per Tenant

```
project/
├── engines/
│   ├── admin/        # Admin panel
│   ├── customer/     # Customer portal
│   └── vendor/       # Vendor dashboard
└── app/              # Public site
```

**Setup:**
```bash
# Setup frontend untuk admin
rails g sun_sword:frontend --setup --engine=admin

# Setup frontend untuk customer
rails g sun_sword:frontend --setup --engine=customer

# Generate user management di admin
rails g sun_sword:scaffold user --engine=admin

# Generate product di customer
rails g sun_sword:scaffold product --engine=customer
```

### Kasus 2: Shared Structure File

```
project/
├── engines/
│   ├── core/
│   │   └── db/
│   │       └── structures/
│   │           ├── user_structure.yaml
│   │           └── product_structure.yaml
│   ├── admin/        # Admin menggunakan structure dari core
│   └── api/          # API menggunakan structure dari core
└── app/
```

**Setup:**
```bash
# Admin engine, ambil structure dari core
rails g sun_sword:scaffold user --engine=admin --engine_structure=core

# API engine, ambil structure dari core
rails g sun_sword:scaffold user --engine=api --engine_structure=core
```

### Kasus 3: Independent Engines

```
project/
├── engines/
│   ├── blog/
│   │   └── db/
│   │       └── structures/
│   │           └── post_structure.yaml
│   └── shop/
│       └── db/
│           └── structures/
│               └── product_structure.yaml
└── app/
```

**Setup:**
```bash
# Blog dengan structure sendiri
rails g sun_sword:scaffold post --engine=blog --engine_structure=blog

# Shop dengan structure sendiri
rails g sun_sword:scaffold product --engine=shop --engine_structure=shop
```

---

## Error Handling

### Engine tidak ditemukan:
```bash
rails g sun_sword:frontend --setup --engine=unknown
# Error: Engine 'unknown' not found. Available engines: admin, api, core
```

### Structure file tidak ditemukan:
```bash
rails g sun_sword:scaffold user --engine=admin --engine_structure=unknown
# Error: Structure file not found in engine 'unknown'
```

---

## Path Resolution

Generator akan mencari engine di urutan berikut:
1. `engines/[engine_name]/`
2. `components/[engine_name]/`
3. `gems/[engine_name]/`
4. `[engine_name]/` (root level)

Setiap path akan divalidasi dengan memastikan file `[engine_name].gemspec` ada.

---

## File yang Digenerate

### Frontend Generator

**Main app** (`--engine` tidak diset):
```
app/
├── frontend/
├── controllers/
├── views/
└── helpers/
```

**Dengan engine** (`--engine=admin`):
```
engines/admin/app/
├── frontend/
├── controllers/
├── views/
└── helpers/
```

### Scaffold Generator

**Main app**:
```
app/
├── controllers/
│   └── [scope]/[resource]_controller.rb
└── views/
    └── [scope]/[resource]/
```

**Dengan engine** (`--engine=admin`):
```
engines/admin/
├── app/
│   ├── controllers/
│   │   └── [scope]/[resource]_controller.rb
│   └── views/
│       └── [scope]/[resource]/
└── config/
    └── routes.rb  # Routes inject ke engine routes
```

---

## Best Practices

1. **Konsisten dengan struktur**: Pilih satu pattern (engines/ atau components/) dan stick with it
2. **Shared structures**: Simpan structure files di engine 'core' atau 'shared' untuk reusability
3. **Engine naming**: Gunakan nama yang descriptive (admin, api, blog, shop)
4. **Testing**: Test setiap engine secara independent
5. **Documentation**: Dokumentasikan engine mana yang punya structure apa

---

## Migration dari Non-Engine

Jika Anda punya existing app tanpa engine:

```bash
# 1. Buat folder engines
mkdir -p engines/admin

# 2. Buat gemspec untuk engine
touch engines/admin/admin.gemspec

# 3. Generate struktur baru
rails g sun_sword:frontend --setup --engine=admin
rails g sun_sword:scaffold user --engine=admin

# 4. Move existing files ke engine (manual)
# 5. Update references
```

---

## Troubleshooting

### Q: Generator tidak menemukan engine saya
**A:** Pastikan file `[engine_name].gemspec` ada di root engine folder.

### Q: Structure file tidak ditemukan
**A:** Cek path `[engine]/db/structures/[name]_structure.yaml` ada.

### Q: Routes tidak ter-inject
**A:** Pastikan `[engine]/config/routes.rb` ada dan readable.

### Q: Views tidak terbuat
**A:** Pastikan `[engine]/app/views/` directory exists.

---

## Contoh Lengkap

```bash
# Setup project dengan 3 engines
mkdir -p engines/{admin,api,blog}

# Buat gemspec untuk setiap engine
echo 'Gem::Specification.new { |s| s.name = "admin" }' > engines/admin/admin.gemspec
echo 'Gem::Specification.new { |s| s.name = "api" }' > engines/api/api.gemspec
echo 'Gem::Specification.new { |s| s.name = "blog" }' > engines/blog/blog.gemspec

# Setup frontend untuk admin
rails g sun_sword:frontend --setup --engine=admin

# Buat structure file di blog
mkdir -p engines/blog/db/structures
cp db/structures/post_structure.yaml engines/blog/db/structures/

# Generate post scaffold di blog dengan structure dari blog
rails g sun_sword:scaffold post --engine=blog --engine_structure=blog

# Generate user di admin dengan structure dari main app
rails g sun_sword:scaffold user --engine=admin
```

---

## Changelog

### v0.0.12
- ✨ Added engine support for frontend generator
- ✨ Added engine support for scaffold generator
- ✨ Added `--engine_structure` option
- ✨ Auto-detect engine paths
- 📝 Added ENGINE_SUPPORT.md documentation

---

**Happy coding with modular Rails! 🎉**

