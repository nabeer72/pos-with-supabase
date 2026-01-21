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

-- Loyalty Accounts Table
create table public.loyalty_accounts (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  customer_id uuid references public.customers(id) not null unique,
  total_points numeric default 0.0,
  cashback_balance numeric default 0.0,
  current_tier text default 'Bronze',
  lifetime_spend numeric default 0.0,
  admin_id text
);

-- Loyalty Transactions Table
create table public.loyalty_transactions (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  invoice_id uuid references public.sales(id),
  customer_id uuid references public.customers(id) not null,
  points_earned numeric default 0.0,
  points_redeemed numeric default 0.0,
  cashback_earned numeric default 0.0,
  cashback_used numeric default 0.0,
  admin_id text
);

-- Loyalty Tier Settings Table
create table public.loyalty_tier_settings (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  tier_name text not null,
  spend_range_min numeric default 0.0,
  spend_range_max numeric default 0.0,
  discount_percentage numeric default 0.0,
  admin_id text,
  unique(tier_name, admin_id)
);

-- Loyalty Rules Table
create table public.loyalty_rules (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  points_per_currency_unit numeric default 1.0,
  cashback_percentage numeric default 0.0,
  points_expiry_months integer default 12,
  admin_id text unique
);

-- Expense Heads Table
create table public.expense_heads (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  name text,
  admin_id text,
  unique(name, admin_id)
);

-- Purchase Orders Table
create table public.purchase_orders (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  supplier_id uuid references public.suppliers(id),
  order_date text not null,
  expected_date text,
  status text not null default 'Draft',
  total_amount numeric default 0.0,
  notes text,
  admin_id text
);

-- Purchase Items Table
create table public.purchase_items (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  purchase_id uuid references public.purchase_orders(id) on delete cascade,
  product_id uuid references public.products(id),
  quantity integer not null default 0,
  received_quantity integer not null default 0,
  unit_cost numeric not null default 0.0,
  admin_id text
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
alter table public.loyalty_accounts enable row level security;
alter table public.loyalty_transactions enable row level security;
alter table public.loyalty_tier_settings enable row level security;
alter table public.loyalty_rules enable row level security;
alter table public.expense_heads enable row level security;
alter table public.purchase_orders enable row level security;
alter table public.purchase_items enable row level security;

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
create policy "Allow all access" on public.loyalty_accounts for all using (true);
create policy "Allow all access" on public.loyalty_transactions for all using (true);
create policy "Allow all access" on public.loyalty_tier_settings for all using (true);
create policy "Allow all access" on public.loyalty_rules for all using (true);
create policy "Allow all access" on public.expense_heads for all using (true);
create policy "Allow all access" on public.purchase_orders for all using (true);
create policy "Allow all access" on public.purchase_items for all using (true);

