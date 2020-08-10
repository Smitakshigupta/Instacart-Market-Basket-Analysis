# Instacart-Market-Basket-Analysis

Project Outline - Instacart is a grocery ordering and delivery app which aims to make it easy to fill customer’s refrigerator and pantry with his/her personal favorites and staples when they need them. After selecting products through the Instacart app, a personal shopper reviews the orders placed by the customer and do the in-store shopping and delivery to the customer.

Instacart is looking to build a robust algorithm to predict which product will be ordered by the customer next. 

Project Goal - The goal of the project is to understand which products are purchased together and then recommend the products based on the users’ cart.

What is Market Basket Analysis?

Market basket analysis (MBA) is a set of statistical affinity calculations that help managers better understand – and ultimately serve – their customers by highlighting purchasing patterns in a retail or restaurant space. MBA shows what combinations of products most frequently occur together in orders. These relationships can be used to increase profitability through cross-selling, recommendations, promotions, or even the placement of items on a menu or in a store.

Itemset - A collection of items purchased by the customer

Antecedent - The set of items on the left side of the rule

Consequent - The set of items on the right side of the rule

Support - Support is the relative frequency that the rules show up.

Confidence - Confidence is a measure of the reliability of the rule. A confidence of .5 in the above example would mean that in 50% of the cases where Diaper and Gum were purchased, the purchase also included Beer and Chips. For product recommendation, a 50% confidence may be perfectly acceptable but in a medical situation, this level may not be high enough.

Lift is the ratio of the observed support to that expected if the two rules were independent. A basic rule of thumb is that a lift value close to 1 means the rules were completely independent. 
Lift values > 1 are generally more “interesting” and could be indicative of a useful rule pattern.

A lift greater than 1 suggests that the presence of the antecedent increases the chances that the consequent will occur in a given transaction
Lift below 1 indicates that purchasing the antecedent reduces the chances of purchasing the consequent in the same transaction. Note: This could indicate that the items are seen by customers as alternatives to each other.
When the lift is 1, then purchasing the antecedent makes no difference on the chances of purchasing the consequent.

Our getting an idea of the products bought together, we will build a collaborative filtering to recommend the products to the customers. The goal is to use a cosine/jaccard similarity.

Association Rules concludes that if someone buys Organic Strawberries, we can recommend Organic Bananas 

User-based collaborative filtering suggests that if someone buys 1% Low Fat Milk, we can recommend 2% Low Fat Milk. 
