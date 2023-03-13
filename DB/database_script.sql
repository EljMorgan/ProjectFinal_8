
CREATE TABLE food_class (
	food_type TEXT, 
	id_food_type BIGINT NOT NULL, 
	PRIMARY KEY (id_food_type)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE utf8mb4_0900_ai_ci

;


CREATE TABLE ingredients_unique (
	ingredient_name TEXT, 
	ingredient_id DOUBLE NOT NULL AUTO_INCREMENT, 
	PRIMARY KEY (ingredient_id)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE utf8mb4_0900_ai_ci

;


CREATE TABLE recipe_main (
	recipe_id BIGINT NOT NULL, 
	recipe_name TEXT, 
	minutes BIGINT, 
	steps TEXT, 
	n_steps BIGINT, 
	n_ingredients BIGINT, 
	rating DOUBLE, 
	id_food_type BIGINT, 
	PRIMARY KEY (recipe_id), 
	CONSTRAINT fk_id_foodclass FOREIGN KEY(id_food_type) REFERENCES food_class (id_food_type)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE utf8mb4_0900_ai_ci

;


CREATE TABLE recipe_nutrition (
	recipe_id BIGINT NOT NULL, 
	calories DOUBLE, 
	total_fat DOUBLE, 
	sugar DOUBLE, 
	sodium DOUBLE, 
	protein DOUBLE, 
	saturated_fat DOUBLE, 
	carbohydrates DOUBLE, 
	id INTEGER NOT NULL AUTO_INCREMENT, 
	PRIMARY KEY (id), 
	CONSTRAINT fk_id_recipe FOREIGN KEY(recipe_id) REFERENCES recipe_main (recipe_id)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE utf8mb4_0900_ai_ci

;


CREATE TABLE recipes_ingredients (
	recipe_id BIGINT, 
	ingredient_id DOUBLE, 
	id INTEGER NOT NULL AUTO_INCREMENT, 
	PRIMARY KEY (id), 
	CONSTRAINT fk_ingr_id FOREIGN KEY(ingredient_id) REFERENCES ingredients_unique (ingredient_id), 
	CONSTRAINT fk_recipe_id FOREIGN KEY(recipe_id) REFERENCES recipe_main (recipe_id)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE utf8mb4_0900_ai_ci

;

