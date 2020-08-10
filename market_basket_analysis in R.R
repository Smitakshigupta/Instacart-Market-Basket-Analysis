 #MARKET BASKET ANALYSIS & RECOMMENDATION SYSTEMS ----

# Installing Important Libraries

# Core & Viz
library(vroom)
library(tidyverse)
library(tidyquant)
library(plotly)

# Modeling
library(recommenderlab)
library(arules)
library(arulesViz)

getwd()

# Importing the data
orders_products_tbl <- vroom("order_products__train.csv", delim = ",")
orders_products_tbl

orders_tbl <- vroom("orders.csv", delim = ",")
orders_tbl

products_tbl <- vroom("products.csv", delim = ",")
products_tbl

aisles_tbl <- vroom("aisles.csv", delim = ",")
aisles_tbl

departments_tbl <- vroom("departments.csv", delim = ",")
departments_tbl


# Data Exploration
#Left join - used in place of SQL - idea got from R-Community

orders_combined_tbl <- orders_products_tbl %>%
    left_join(orders_tbl) %>%
    left_join(products_tbl) %>%
    left_join(aisles_tbl) %>%
    left_join(departments_tbl) %>% 
    select(eval_set, user_id, 
           contains("order"), contains("product"), 
           contains("aisle"), contains("department"), everything()) 

orders_combined_tbl %>% glimpse()

#Which products are purchased most frequently? 

item_frequency_tbl <- orders_combined_tbl %>%
    count(product_name, product_id, aisle, department) %>%
    arrange(desc(n)) %>%
    mutate(
        pct = n / sum(n),
        cumulative_pct = cumsum(pct),
        popular_product = ifelse(cumulative_pct <= 0.5, "Yes", "No")
    ) %>%
    rowid_to_column(var = "rank") %>%
    mutate(label_text = str_glue("Rank: {rank}
                                 Product: {product_name}
                                 ProductID: {product_id}
                                 Aisle: {aisle}
                                 Department: {department}
                                 Count: {n}
                                 Pct: {scales::percent(pct)}
                                 Cumulative Pct: {scales::percent(cumulative_pct)}")) 
    

item_frequency_tbl

g <- item_frequency_tbl %>%
    slice(1:5000) %>%
    ggplot(aes(rank, n)) +
    geom_point(aes(size = n, color = popular_product, text = label_text), alpha = 0.2) +
    theme_tq() +
    scale_color_tq() +
    theme(legend.direction = "vertical", 
          legend.position  = "right") +
    labs(title = "Item Frequency", 
         subtitle = "Top Items Account For Majority Of Purchases")

ggplotly(g, tooltip = "text")

# Do Customers Purchase More Frequently? 

user_frequency_tbl <- orders_combined_tbl %>%
    distinct(user_id, order_id) %>%
    count(user_id) %>%
    arrange(desc(n)) %>%
    mutate(
        pct = n / sum(n),
        cumulative_pct = cumsum(pct),
        popular_customer = ifelse(cumulative_pct <= 0.5, "Yes", "No")
    ) %>%
    rowid_to_column(var = "rank") 


user_frequency_tbl

g <- user_frequency_tbl %>%
    slice(1:5000) %>%
    ggplot(aes(rank, n)) +
    geom_point(aes(size = n, color = popular_customer), alpha = 0.2) +
    theme_tq() +
    scale_color_tq() +
    theme(legend.direction = "vertical", 
          legend.position  = "right") +
    labs(title = "User Frequency", 
         subtitle = "How Often Do You Shop? - No Frequency! Everyone is 1st time.")

ggplotly(g)

# Do Certain Customers Buy More Products?

user_item_frequency_tbl <- orders_combined_tbl %>%
    count(user_id) %>%
    arrange(desc(n)) %>%
    mutate(
        pct = n / sum(n),
        cumulative_pct = cumsum(pct),
        popular_customer = ifelse(cumulative_pct <= 0.5, "Yes", "No")
    ) %>%
    rowid_to_column(var = "rank") 


user_item_frequency_tbl

g <- user_item_frequency_tbl %>%
    slice(1:10000) %>% #Just plotting the first 1000 products based on largest baskets 
    ggplot(aes(rank, n)) +
    geom_point(aes(size = n, color = popular_customer), alpha = 0.2) +
    theme_tq() +
    scale_color_tq() +
    theme(legend.direction = "vertical", 
          legend.position  = "right") +
    labs(title = "User Frequency", 
         subtitle = "Yes - Some Customers have larger baskets")

ggplotly(g) #The tail is shorter so maybe add more customers.


#MBA needs transaction data so we will convert the data into transactional and trim down the data(maybe popularity)

# Popular Products
top_products_vec <- item_frequency_tbl %>%
    filter(popular_product == "Yes") %>%
    pull(product_name)

# Use names to filter 
top_products_basket_tbl <- orders_combined_tbl %>%
    filter(product_name %in% top_products_vec) 

top_products_basket_tbl %>% glimpse()

# Large Baskets
top_users_vec <- user_item_frequency_tbl %>%
    filter(rank < 2500) %>%
    pull(user_id)

market_basket_condensed_tbl <- top_products_basket_tbl %>%
    filter(user_id %in% top_users_vec) 

market_basket_condensed_tbl


# Market Basket Analysis
# Changing the data format to convert it into a binaryRatingMatrix

#  Did basket contain an item (Yes/No encoded as 1-0)
#Need to install recommenderlab

install.packages("recommenderlab")
library("recommenderlab")

user_item_tbl <- market_basket_condensed_tbl %>%
    select(user_id, product_name) %>%
    mutate(value = 1) %>%
    spread(product_name, value, fill = 0)

user_item_rlab <- user_item_tbl %>%
    select(-user_id) %>%
    as.matrix() %>%
    as("binaryRatingMatrix") 

user_item_rlab

#  Relationship with arules package

user_item_rlab@data

user_item_rlab@data %>% summary()

user_item_rlab@data %>% glimpse()

# dev.off()
itemFrequencyPlot(user_item_rlab@data, topN=30, type="absolute",
                  xlab = "Items", ylab = "Frequency (absolute)",
                  col = "steelblue",
                  main = "Absolute Frequency Plot")



# Implementing market basket analysis - Analyzing the different association rules
recommenderRegistry$get_entries()

eval_recipe <- user_item_rlab %>%
    evaluationScheme(method = "cross-validation", k = 5, given = -1)

eval_recipe

# Association Rules

algorithms_list <- list(
    "association rules1"   = list(name  = "AR", 
                                  param = list(supp = 0.01, conf = 0.01)),
    "association rules2"  = list(name  = "AR", 
                                 param = list(supp = 0.01, conf = 0.1)),
    "association rules3"  = list(name  = "AR", 
                                 param = list(supp = 0.01, conf = 0.5)),
    "association rules4"  = list(name  = "AR", 
                                 param = list(supp = 0.1, conf = 0.5))
)


results_rlab_arules <- eval_recipe %>%
    recommenderlab::evaluate(
        method    = algorithms_list, 
        type      = "topNList", 
        n         = 1:10)

results_rlab_arules <- read_rds("results_arules.rds")

plot(results_rlab_arules, annotate = TRUE)

# Implementing all  the different algorithms

algorithms_list <- list(
    "random items"        = list(name  = "RANDOM",
                                 param = NULL),
    "popular items"       = list(name  = "POPULAR",
                                 param = NULL),
    "user-based CF"       = list(name  = "UBCF",
                                 param = list(method = "Cosine", nn = 500)),
    "item-based CF"       = list(name  = "IBCF",
                                 param = list(k = 5)),
    "association rules2"  = list(name  = "AR", 
                                 param = list(supp = 0.01, conf = 0.1))
)


results_rlab <- eval_recipe %>%
    recommenderlab::evaluate(
        method    = algorithms_list, 
        type      = "topNList", 
        n         = 1:10)

results_rlab <- read_rds("results_all_models.rds")

plot(results_rlab, annotate = TRUE)


# Building the model

#Association rules 
model_ar <- recommenderlab::Recommender(
    data = user_item_rlab, 
    method = "AR", 
    param = list(supp = 0.01, conf = 0.10))


# User-based collaborative filtering
model_ucbf <- recommenderlab::Recommender(
    data = user_item_rlab, 
    method = "UBCF", 
    param  = list(method = "Cosine", nn = 500)) #nearest neighbors


# Analyze the results

rules <- model_ar@model$rule_base

# Visualization
inspectDT(rules)

plotly_arules(rules, method = "scatterplot", 
              marker = list(opacity = .7, size = ~lift), 
              colors = c("blue", "green"))


sort(rules, by = "lift", decreasing = TRUE)[1:20] %>%
    inspect() 

plot(rules, method = "graph")

plot(model_ar@model$rule_base, method = "graph", 
     control=list(layout=igraph::in_circle()))



# Final Prediction for a new user

# Testing on the new data
new_user_basket <- c("Organic Banana", "Organic Whole Milk")

new_user_basket_rlab <- tibble(items = user_item_rlab@data %>% colnames()) %>%
    mutate(value = as.numeric(items %in% new_user_basket)) %>%
    spread(key = items, value = value) %>%
    as.matrix() %>%
    as("binaryRatingMatrix")

new_user_basket_rlab

# Association rules

prediction_ar <- predict(model_ar, newdata = new_user_basket_rlab, n = 3)

tibble(items = prediction_ar@itemLabels) %>%
    slice(prediction_ar@items[[1]])

# User Based Collaborative Filtering

prediction_ucbf <- predict(model_ucbf, newdata = new_user_basket_rlab, n = 3)

tibble(items = prediction_ucbf@itemLabels) %>%
    slice(prediction_ucbf@items[[1]])
