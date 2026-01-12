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
  last_active text
);

-- Categories Table
create table public.categories (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  name text unique
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
  icon integer
);

-- Customers Table
create table public.customers (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  name text,
  address text,
  "cellNumber" text,
  email text,
  type integer,
  "isActive" integer
);

-- Sales Table
create table public.sales (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  "saleDate" text,
  "totalAmount" numeric,
  customer_id uuid references public.customers(id)
);

-- Sale Items Table
create table public.sale_items (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  sale_id uuid references public.sales(id),
  product_id uuid references public.products(id),
  quantity integer,
  "unitPrice" numeric
);

-- Expenses Table
create table public.expenses (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  category text,
  amount numeric,
  date text
);

-- Suppliers Table
create table public.suppliers (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  name text,
  contact text,
  "lastOrder" text
);

-- Enable Row Level Security (RLS) - Optional but recommended
alter table public.users enable row level security;
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.customers enable row level security;
alter table public.sales enable row level security;
alter table public.sale_items enable row level security;
alter table public.expenses enable row level security;
alter table public.suppliers enable row level security;

-- Create policies to allow public access (Since we are using Anon Key for now in the app)
-- Ideally, you should restrict this in production.
create policy "Allow all access" on public.users for all using (true);
create policy "Allow all access" on public.categories for all using (true);
create policy "Allow all access" on public.products for all using (true);
create policy "Allow all access" on public.customers for all using (true);
create policy "Allow all access" on public.sales for all using (true);
create policy "Allow all access" on public.sale_items for all using (true);
create policy "Allow all access" on public.expenses for all using (true);
create policy "Allow all access" on public.suppliers for all using (true);
