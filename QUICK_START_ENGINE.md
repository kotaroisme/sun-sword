# Quick Start - Engine Support

Panduan cepat menggunakan sun-sword dengan Rails Engine.

---

## 🚀 Setup Awal

### 1. Buat Engine Structure

```bash
# Di root project Rails Anda
mkdir -p engines/admin
mkdir -p engines/api

# Buat gemspec untuk setiap engine (required!)
cat > engines/admin/admin.gemspec << 'EOF'
Gem::Specification.new do |spec|
  spec.name        = "admin"
  spec.version     = "0.0.1"
  spec.authors     = ["Your Name"]
  spec.summary     = "Admin Engine"
  
  spec.files = Dir["{app,config,db,lib}/**/*"]
end
EOF

cat > engines/api/api.gemspec << 'EOF'
Gem::Specification.new do |spec|
  spec.name        = "api"
  spec.version     = "0.0.1"
  spec.authors     = ["Your Name"]
  spec.summary     = "API Engine"
  
  spec.files = Dir["{app,config,db,lib}/**/*"]
end
EOF
```

### 2. Buat Basic Engine Structure

```bash
# Admin engine
mkdir -p engines/admin/{app,config,db/structures}
touch engines/admin/config/routes.rb

# API engine
mkdir -p engines/api/{app,config,db/structures}
touch engines/api/config/routes.rb
```

---

## 📦 Generate Frontend

### Main App Only (Engine Tidak Didukung)
```bash
rails g sun_sword:frontend --setup
# Files di: app/frontend/, app/controllers/, app/views/
```

**Catatan:** Frontend generator tidak mendukung engine. Hanya bisa digunakan untuk main app.

---

## 🏗️ Generate Scaffold

### Scenario 1: Main App (Default)

```bash
# Buat structure file
cat > db/structures/user_structure.yaml << 'EOF'
model: User
resource_name: users
actor: admin
domains:
  action_list:
    use_case:
      contract: [id, name, email]
  action_fetch_by_id:
    use_case:
      contract: [id, name, email]
  action_create:
    use_case:
      contract: [name, email]
  action_update:
    use_case:
      contract: [name, email]
  action_destroy:
    use_case:
      contract: [id]
controllers:
  form_fields:
    - {name: name, type: string}
    - {name: email, type: string}
EOF

# Generate
rails g sun_sword:scaffold user
```

### Scenario 2: Generate ke Engine Admin

```bash
# Option A: Ambil structure dari main app
rails g sun_sword:scaffold user --engine=admin
# Files di: engines/admin/app/controllers/
#           engines/admin/app/views/
# Structure dari: db/structures/user_structure.yaml

# Option B: Ambil structure dari engine admin sendiri
cp db/structures/user_structure.yaml engines/admin/db/structures/
rails g sun_sword:scaffold user --engine=admin --engine_structure=admin
# Files di: engines/admin/app/
# Structure dari: engines/admin/db/structures/user_structure.yaml
```

### Scenario 3: Shared Structure (Recommended!)

```bash
# 1. Buat core engine untuk shared structures
mkdir -p engines/core/db/structures
cat > engines/core/core.gemspec << 'EOF'
Gem::Specification.new do |spec|
  spec.name = "core"
  spec.version = "0.0.1"
end
EOF

# 2. Simpan structure di core
cp db/structures/user_structure.yaml engines/core/db/structures/
cp db/structures/product_structure.yaml engines/core/db/structures/

# 3. Generate ke berbagai engine, ambil structure dari core
rails g sun_sword:scaffold user --engine=admin --engine_structure=core
rails g sun_sword:scaffold user --engine=api --engine_structure=core
rails g sun_sword:scaffold product --engine=admin --engine_structure=core
```

---

## 🎯 Use Cases Nyata

### Multi-Tenant dengan Engine per Role

```
project/
├── engines/
│   ├── admin/          # Admin dashboard
│   ├── customer/       # Customer portal
│   ├── vendor/         # Vendor management
│   └── core/           # Shared structures
└── app/                # Public site
```

**Setup:**
```bash
# 1. Setup frontend di main app (hanya sekali, untuk semua engines)
rails g sun_sword:frontend --setup

# 2. Buat shared structures di core
mkdir -p engines/core/db/structures
cp db/structures/*.yaml engines/core/db/structures/

# 3. Generate scaffolds
rails g sun_sword:scaffold user --engine=admin --engine_structure=core
rails g sun_sword:scaffold product --engine=admin --engine_structure=core
rails g sun_sword:scaffold order --engine=customer --engine_structure=core
rails g sun_sword:scaffold inventory --engine=vendor --engine_structure=core
```

### API-first Architecture

```
project/
├── engines/
│   ├── api_v1/         # API version 1
│   ├── api_v2/         # API version 2
│   └── web/            # Web interface
└── app/                # Landing page
```

**Setup:**
```bash
# Setup frontend di main app (hanya sekali)
rails g sun_sword:frontend --setup

# Generate resources ke berbagai engines
rails g sun_sword:scaffold user --engine=api_v1
rails g sun_sword:scaffold user --engine=api_v2  # Different implementation
rails g sun_sword:scaffold user --engine=web
```

---

## ✅ Checklist

Sebelum generate, pastikan:

- [ ] Engine folder exists (`engines/[name]/`)
- [ ] Gemspec file exists (`engines/[name]/[name].gemspec`)
- [ ] Config routes exists (`engines/[name]/config/routes.rb`)
- [ ] Structure file exists di target engine atau main app

---

## 🔍 Debugging

### Cek engine yang terdeteksi:
```bash
# Temporary script untuk list engines
ruby -e "
['engines', 'components', 'gems'].each do |dir|
  next unless Dir.exist?(dir)
  Dir.glob(File.join(dir, '*')).each do |path|
    engine = File.basename(path)
    gemspec = File.join(path, '#{engine}.gemspec')
    puts '✅ #{engine}' if File.exist?(gemspec)
  end
end
"
```

### Error: Engine not found
```bash
# Pastikan gemspec ada
ls -la engines/admin/admin.gemspec

# Jika tidak ada, buat:
touch engines/admin/admin.gemspec
echo 'Gem::Specification.new { |s| s.name = "admin" }' > engines/admin/admin.gemspec
```

### Error: Structure file not found
```bash
# Cek path structure
ls -la engines/admin/db/structures/user_structure.yaml
# atau
ls -la db/structures/user_structure.yaml

# Buat directory jika perlu
mkdir -p engines/admin/db/structures
```

---

## 📚 Referensi Lengkap

Lihat dokumentasi lengkap di:
- [ENGINE_SUPPORT.md](ENGINE_SUPPORT.md) - Full documentation
- [README.md](README.md) - General usage
- [USAGE](lib/generators/sun_sword/USAGE) - Generator examples

---

## 💡 Tips

1. **Gunakan core engine** untuk structure files yang shared
2. **Konsisten dengan naming**: admin, api, web (lowercase)
3. **Test per engine** dengan mounting di routes
4. **Separate concerns**: Admin di admin engine, API di api engine
5. **Version your APIs**: api_v1, api_v2, dst

---

**Happy coding with modular Rails! 🚀**

