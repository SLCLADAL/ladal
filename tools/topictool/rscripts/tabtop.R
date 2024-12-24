require(dplyr)
require(tidytext)
require(tidyr)


tabtop <- function(x, n) {
  tidytext::tidy(x, matrix = "beta") %>%
    dplyr::group_by(topic) %>%
    dplyr::slice_max(beta, n = n) %>%
    dplyr::ungroup() %>%
    dplyr::arrange(topic, -beta) %>%
    dplyr::mutate(
      term = paste(term, " (", round(beta, 3), ")", sep = ""),
      topic = paste("topic", topic),
      top = rep(paste("top", 1:n), each = 1, length.out = nrow(.)), # Ensure correct grouping
      top = factor(top, levels = c(paste("top", 1:n)))
    ) %>%
    dplyr::select(-beta) %>%
    tidyr::pivot_wider(names_from = topic, values_from = term) # Use pivot_wider for better handling
}
