// src/main/java/com/church/cms/service/UserDetailsServiceImpl.java
package com.church.cms.service;

import com.church.cms.entity.User;
import com.church.cms.entity.UserRole;
import com.church.cms.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Service
public class UserDetailsServiceImpl implements UserDetailsService {

    private static final Logger logger = LoggerFactory.getLogger(UserDetailsServiceImpl.class);

    @Autowired
    UserRepository userRepository;

    @Override
    @Transactional
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
        User user = userRepository.findByEmail(email) // Asumsi Anda punya findByEmail di UserRepository
                .orElseThrow(() -> {
                    logger.warn("User Not Found with email: {}", email);
                    return new UsernameNotFoundException("User Not Found with email: " + email);
                });

        logger.info("User found: ID={}, Email={}", user.getId(), user.getEmail());
        logger.info("Stored password hash for {}: {}", user.getEmail(), user.getPasswordHash()); // LOG INI

        List<String> roles = user.getUserRoles().stream()
                .map(UserRole::getRole)
                .map(role -> role.getName().toUpperCase()) // Convert role name to uppercase for Spring Security
                .collect(Collectors.toList());

        return UserDetailsImpl.build(user, roles);
    }
}