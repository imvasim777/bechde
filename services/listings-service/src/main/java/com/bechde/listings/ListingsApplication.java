package com.bechde.listings;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
@org.springframework.boot.autoconfigure.SpringBootApplication(scanBasePackages = "com.bechde.listings")
@org.springframework.data.jpa.repository.config.EnableJpaRepositories(basePackages = "com.bechde.listings.repo")
@org.springframework.boot.autoconfigure.domain.EntityScan(basePackages = "com.bechde.listings.domain")
public class ListingsApplication {
    public static void main(String[] args) { SpringApplication.run(ListingsApplication.class, args); }
}
