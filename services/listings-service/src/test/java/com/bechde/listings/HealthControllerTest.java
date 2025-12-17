package com.bechde.listings;

import static org.assertj.core.api.Assertions.assertThat;
import org.junit.jupiter.api.Test;

public class HealthControllerTest {
    @Test
    void health_returnsOk() {
        var c = new HealthController();
        assertThat(c.health()).isEqualTo("ok");
    }
}
