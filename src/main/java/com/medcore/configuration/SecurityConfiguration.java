package com.medcore.configuration;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.provisioning.InMemoryUserDetailsManager;
import org.springframework.beans.factory.annotation.Value;

@Configuration
@EnableMethodSecurity
public class SecurityConfiguration {
    @Bean
    UserDetailsService userDetailsService(@Value("${MEDCORE_VIEWER_PASSWORD:local-view-only}") String viewerPassword,
                                          @Value("${MEDCORE_OPERATOR_PASSWORD:local-operations-only}") String operatorPassword) {
        var viewer = User.withUsername("gestor").password("{noop}" + viewerPassword)
                .authorities("reports.view", "financial.view", "accounting.view", "billing.view", "inventory.view", "audit.view").build();
        var operator = User.withUsername("analista").password("{noop}" + operatorPassword)
                .authorities("reports.view", "financial.view", "financial.settle", "accounting.view", "billing.view", "inventory.view", "audit.view", "admission.transfer").build();
        return new InMemoryUserDetailsManager(viewer, operator);
    }

    @Bean
    SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        return http
                .csrf(csrf -> csrf.ignoringRequestMatchers("/api/**"))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/actuator/health", "/v3/api-docs/**", "/swagger-ui/**", "/swagger-ui.html").permitAll()
                        .anyRequest().authenticated())
                .httpBasic(Customizer.withDefaults())
                .build();
    }
}
