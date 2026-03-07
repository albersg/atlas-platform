export type Product = {
  id: string;
  name: string;
  sku: string;
  price: string;
  stock: number;
};

export type CreateProductInput = {
  name: string;
  sku: string;
  price: number;
  stock: number;
};
