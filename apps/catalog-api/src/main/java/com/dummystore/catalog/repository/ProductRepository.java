package com.dummystore.catalog.repository;

import com.dummystore.catalog.model.Product;
import jakarta.annotation.PostConstruct;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;
import java.util.stream.Collectors;

@Repository
public class ProductRepository {

    private final Map<Long, Product> store = new ConcurrentHashMap<>();
    private final AtomicLong idGenerator = new AtomicLong(1);

    @PostConstruct
    public void seedData() {
        save(new Product(null, "Wireless Mouse", "Ergonomic wireless mouse with USB receiver", new BigDecimal("29.99"), "Electronics", 150));
        save(new Product(null, "Mechanical Keyboard", "RGB mechanical keyboard with Cherry MX switches", new BigDecimal("89.99"), "Electronics", 75));
        save(new Product(null, "USB-C Hub", "7-in-1 USB-C hub with HDMI, USB-A, SD card", new BigDecimal("34.99"), "Accessories", 200));
        save(new Product(null, "Laptop Stand", "Adjustable aluminum laptop stand", new BigDecimal("49.99"), "Accessories", 120));
        save(new Product(null, "Noise Cancelling Headphones", "Over-ear Bluetooth headphones with ANC", new BigDecimal("199.99"), "Audio", 50));
    }

    public List<Product> findAll() {
        return List.copyOf(store.values());
    }

    public Product findById(Long id) {
        return store.get(id);
    }

    public List<Product> findByCategory(String category) {
        return store.values().stream()
                .filter(p -> p.getCategory().equalsIgnoreCase(category))
                .collect(Collectors.toList());
    }

    public Product save(Product product) {
        if (product.getId() == null) {
            product.setId(idGenerator.getAndIncrement());
        }
        store.put(product.getId(), product);
        return product;
    }
}
