-- UPDATED SUPABASE SCHEMA FOR ADMIN ISOLATION

-- Enable UUID extension if not already enabled
create extension if not exists "uuid-ossp";

-- Users Table
create table public.users (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  name text,
  email text unique,
  password text,
  role text,
  permissions text,
  last_active text,
  admin_id text -- Added for multi-tenancy
);

-- Categories Table
create table public.categories (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  name text,
  admin_id text,
  unique(name, admin_id)
);

-- Products Table
create table public.products (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  name text,
  barcode text,
  price numeric,
  category text,
  quantity integer,
  color integer,
  icon integer,
  admin_id text,
  purchase_price numeric,
  unique(barcode, admin_id)
);

-- Customers Table
create table public.customers (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  name text,
  address text,
  cell_number text,
  email text,
  type integer,
  is_active boolean default true,
  admin_id text,
  discount decimal default 0.0,
  unique(name, admin_id)
);

-- Sales Table
create table public.sales (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  sale_date text,
  total_amount numeric,
  customer_id uuid references public.customers(id),
  admin_id text
);

-- Sale Items Table
create table public.sale_items (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  sale_id uuid references public.sales(id),
  product_id uuid references public.products(id),
  quantity integer,
  unit_price numeric,
  admin_id text
);

-- Expenses Table
create table public.expenses (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  category text,
  amount numeric,
  date text,
  admin_id text
);

-- Suppliers Table
create table public.suppliers (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  name text,
  contact text,
  last_order text,
  admin_id text
);

-- Settings Table
create table public.settings (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  key text not null,
  value text,
  admin_id text,
  unique(key, admin_id)
);

-- Enable Row Level Security (RLS)
alter table public.users enable row level security;
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.customers enable row level security;
alter table public.sales enable row level security;
alter table public.sale_items enable row level security;
alter table public.expenses enable row level security;
alter table public.suppliers enable row level security;
alter table public.settings enable row level security;

-- Create policies to allow access
create policy "Allow all access" on public.users for all using (true);
create policy "Allow all access" on public.categories for all using (true);
create policy "Allow all access" on public.products for all using (true);
create policy "Allow all access" on public.customers for all using (true);
create policy "Allow all access" on public.sales for all using (true);
create policy "Allow all access" on public.sale_items for all using (true);
create policy "Allow all access" on public.expenses for all using (true);
create policy "Allow all access" on public.suppliers for all using (true);
create policy "Allow all access" on public.settings for all using (true);
