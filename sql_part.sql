############ CREATING DATABASE ##############
CREATE DATABASE IF NOT EXISTS recipes_recomm ;
USE recipes_recomm;
ALTER TABLE recipe_main DROP FOREIGN KEY id_food_type;

########### SET UP CONNECTION ############
SET GLOBAL connect_timeout=600;

############ CHECKING COMPATIBILITY ############
SELECT count(1), count(distinct ingredient_id) FROM recipes_recomm.ingredients_unique;

select ri.ingredient_id
from recipes_ingredients ri
left join ingredients_unique i
on ri.ingredient_id = i.ingredient_id
where i.ingredient_id is null;

select * from recipes_ingredients where ingredient_id is null;

delete from recipes_ingredients where ingredient_id is null;

########## ADDING PRIMARY KEYS ##################
ALTER TABLE food_class
ADD PRIMARY KEY (id_food_type);

ALTER TABLE ingredients_unique
ADD PRIMARY KEY (ingredient_id);

ALTER TABLE recipe_main
ADD PRIMARY KEY (recipe_id);

ALTER TABLE recipe_nutrition 
ADD COLUMN id INT AUTO_INCREMENT PRIMARY KEY;

ALTER TABLE recipes_ingredients 
ADD COLUMN id INT AUTO_INCREMENT PRIMARY KEY;


############### ADDING FOREIGN KEYS #################
ALTER TABLE recipes_ingredients
DROP FOREIGN KEY fk_recipe_id;

ALTER TABLE recipes_ingredients
ADD CONSTRAINT fk_ingr_id
FOREIGN KEY (ingredient_id)
REFERENCES ingredients_unique(ingredient_id);

ALTER TABLE recipes_ingredients
ADD CONSTRAINT fk_recipe_id
FOREIGN KEY (recipe_id)
REFERENCES recipe_main(recipe_id);

ALTER TABLE recipe_nutrition
ADD CONSTRAINT fk_id_recipe
FOREIGN KEY (recipe_id)
REFERENCES recipe_main(recipe_id);

ALTER TABLE recipe_main
ADD CONSTRAINT fk_id_foodclass
FOREIGN KEY (id_food_type)
REFERENCES food_class(id_food_type);

########### 1.Procedure that retrieves a list of all recipes that contain a specific ingredient
DELIMITER //
CREATE PROCEDURE get_recipes_with_ingredient(IN ingredient_name VARCHAR(50))
BEGIN
    SELECT rm.recipe_name, rm.rating
    FROM recipe_main rm
    JOIN recipes_ingredients ri ON rm.recipe_id = ri.recipe_id
    JOIN ingredients_unique iu ON ri.ingredient_id = iu.ingredient_id
    WHERE iu.ingredient_name = ingredient_name;
END //
DELIMITER ;

######### calling procedure ###########
CALL get_recipes_with_ingredient('chicken');

########### 2. Get Ingredients by Recipe ##########
DELIMITER //

CREATE PROCEDURE get_ingredients_by_recipe(IN recipe_name VARCHAR(50))
BEGIN
    SELECT iu.ingredient_name, rm.n_steps, rm.n_ingredients, rm.minutes
    FROM recipe_main rm
    JOIN recipes_ingredients ri ON rm.recipe_id = ri.recipe_id
    JOIN ingredients_unique iu ON ri.ingredient_id = iu.ingredient_id
    WHERE rm.recipe_name = recipe_name;
END //

DELIMITER ;

####### calling procedure ##########
CALL get_ingredients_by_recipe('cassoulet');

####### 3. View to see the steps of recipe
CREATE VIEW view_recipe_steps AS
SELECT rm.recipe_name, rm.n_steps, rm.steps, fc.food_type
FROM recipe_main rm
JOIN food_class fc ON rm.id_food_type = fc.id_food_type;

###### view the view table
SELECT * FROM view_recipe_steps WHERE recipe_name = 'Spaghetti Bolognese';

####### 4. Most used ingredients in top rated recipes
SELECT iu.ingredient_name, COUNT(*) AS frequency
FROM recipe_main rm
JOIN recipes_ingredients ri ON rm.recipe_id = ri.recipe_id
JOIN ingredients_unique iu ON ri.ingredient_id = iu.ingredient_id
WHERE rm.rating = (SELECT MAX(rating) FROM recipe_main)
GROUP BY iu.ingredient_name
ORDER BY frequency DESC limit 20;

###### 5. The average of all nutritions based on food class only for recipes with rating 5
SELECT fc.food_type, round(AVG(rn.calories), 2) AS avg_calories, round(AVG(rn.protein), 2) AS avg_protein,
					round(AVG(rn.total_fat),2) AS avg_total_fat, round(AVG(rn.carbohydrates), 2) AS avg_carbohydrates, 
                    round(AVG(rn.sugar), 2) AS avg_sugar
FROM (
	SELECT rm.recipe_id, iu.ingredient_id, rm.id_food_type
    FROM recipe_main rm
    JOIN recipes_ingredients ri ON rm.recipe_id = ri.recipe_id
    JOIN ingredients_unique iu ON ri.ingredient_id = iu.ingredient_id
    WHERE rm.rating = 5
) AS t
JOIN food_class fc ON t.id_food_type = fc.id_food_type
JOIN recipe_nutrition rn on t.recipe_id = rn.recipe_id
GROUP BY fc.food_type 
ORDER BY avg_calories DESC limit 20;
