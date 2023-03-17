import streamlit as st
import pandas as pd
import numpy as np
from requests import get
from bs4 import BeautifulSoup as bs
import random
import pickle
import pytube
from wordcloud import WordCloud, get_single_color_func
import matplotlib.pyplot as plt
from fuzzywuzzy import fuzz, process
import textwrap, random
import streamlit.components.v1 as components
import joblib
import re
import time

st.set_page_config(page_title="Foody",page_icon="🍜",initial_sidebar_state="expanded")


@st.cache_data()
def load_model():
    with open('pickles/cosine_sim15k.joblib', 'rb') as f:
        return joblib.load(f)

cosine_sim = load_model()


   
@st.cache_data()
def load_data():
    return pd.read_csv('pickles/recipes_15k_random_joblib.csv', index_col=0)

#cosine_sim = load_model()
subset_recipe = load_data()

def get_name_from_index(index):
    return subset_recipe[subset_recipe.index == index]['name'].values[0]

def get_index_from_name(name):
    return subset_recipe[subset_recipe.name == name].index[0]

def get_name(recipe_to_find, subset_recipe = subset_recipe):
    st.warning(f"Sorry, the {recipe_to_find} recipe you entered could not be found.")
    st.subheader('I found some similar recipe names in my library: ')
    n=3
    all_names = subset_recipe['name'].values.tolist()

    # Find the most similar names using fuzzy matching
    similar_names = process.extract(recipe_to_find, all_names, scorer=fuzz.token_sort_ratio, limit=n)

    # Extract the names and similarity scores
    similar_names = [(n, s) for n, s in process.extract(recipe_to_find, all_names, scorer=fuzz.token_sort_ratio, limit=n)]

    st.write('Similar recipe names:')
    choice=''
    if similar_names:
        for i, (name, score) in enumerate(similar_names):
            f"{i+1}. {name}"
                 
    # Ask user to choose a similar recipe name
    #choice = None
    st.write('Make a choose of the number of the recipe you meant to find: ')
    choice = st.radio(label='Just pick one here: ', options=[1,2,3], key='choice of similarity')

    if not choice:
        return
    try:
        choice = int(choice)
        recipe_to_find = similar_names[choice-1][0]
        recipe_index = get_index_from_name(recipe_to_find)
        st.write(f'_Your choice is:_ {recipe_to_find}')
    except (ValueError, IndexError):
        print('Invalid choice.')
        return
    return recipe_to_find, recipe_index

def get_similar(recipe_index, recipe_to_find, subset_recipe= subset_recipe, cosine_sim=cosine_sim):
    #recipe_to_find = st.text_input("Enter the name of a recipe: ")
    
    try:
        recipe_index = get_index_from_name(recipe_to_find)
    except :
        recipe_index = get_name(recipe_to_find)
   
    similar_rec = list(enumerate(cosine_sim[recipe_index]))
    sorted_similar = sorted(similar_rec, key=lambda x: x[1], reverse=True)[1:]
    
    st.subheader(f"Top 5 similar recipes to '{recipe_to_find}' are:\n")
    for i, element in enumerate(sorted_similar[:5]):
        st.write(f"{i+1}. {get_name_from_index(element[0])} ")
    return sorted_similar

def get_steps(sorted_similar, subset_recipe = subset_recipe):
    # Ask user to choose a similar recipe name
    selected_recipe = None
    st.subheader('Make a choose of the number of the recipe you would like to try: ')
    selected_recipe = st.select_slider('Slide to confirm', options=[1, 2, 3, 4, 5], value=1, key='recipe_selection')
    # Convert the selected recipe to an integer and get its index
    try:
        selected_recipe_index = sorted_similar[int(selected_recipe)-1][0]
    except:
        st.warning("Invalid selection.")
        return
    
    # Get the steps and ingredients for the selected recipe
    recipe_name = get_name_from_index(selected_recipe_index)
    recipe_steps = subset_recipe.loc[selected_recipe_index, 'steps']
    recipe_ingredients = subset_recipe.loc[selected_recipe_index, 'ingredients']

    # Print the steps and ingredients
    st.write(f"\n_Your choice is:_ {recipe_name} {mj}\n")
    st.write(f"\nIngredients you need: \n")
    st.write(recipe_ingredients)
    st.write(f"\nSteps:\n {recipe_steps}")
    
def make_a_cloud(top_similar):
    # Convert top_similar to a list of integer indices
    indices = get_index_from_name(top_similar)

    # Concatenate the descriptions of the top n most similar recipes
    locking = subset_recipe.loc[[indices], ['description']]
    desc_text = ' '.join(locking.values.ravel().tolist())
    def random_color_func(word=None, font_size=None, position=None, orientation=None, font_path=None, random_state=None):
        h = random.randint(0, 359)
        s = random.randint(60, 100)
        l = random.randint(30, 70)
        return "hsl({}, {}%, {}%)".format(h, s, l)
    # Create a word cloud object with the desired parameters
    wordcloud = WordCloud(width=800, height=400,color_func=random_color_func, background_color='rgba(0,0,0,0)', max_words=100).generate(desc_text)

     # Save the word cloud to a file
    image_path = "cloud/wordcloud.png"
    wordcloud.to_file(image_path)

    # Display the word cloud
    st.image(image_path)

def update_params():
    st.experimental_set_query_params(recipe=st.session_state.qp)


mjstr = "🌱🍇🥦🥕🌶️🍄🥑🥐🥨🍖🥩🥓🍔🍟🍕🥗🧂🍦🍬☕"
mjlist = textwrap.wrap(mjstr,width=1)
mj = random.choice(mjlist)
st.title("Recipe Recommendation  "+mj)

param = st.experimental_get_query_params()

# Get the input from the user
recipe_to_find = st.sidebar.text_input('Enter the Ingredient',key='qp',on_change=update_params)

st.sidebar.image('images/healthy-foods.jpg')

#st.experimental_set_query_params(recipe = recipe_to_find)
def app(recipe_to_find):
    recipe_index = None
    #check if the user has entered a recipe name
    if not recipe_to_find:
        st.warning('Please enter a recipe name')
    else:
        #Try to find the index of the recipe using the fuzzy matching function
        try:
            recipe_index = get_index_from_name(recipe_to_find)
            st.write(f'Index of {recipe_to_find}: {recipe_index}')
        except:
            # If the recipe cannot be found, suggest similar recipe names
            
            recipe_to_find, recipe_index = get_name(recipe_to_find)
            
    # display similar recipe names
    if recipe_to_find:
        make_a_cloud(recipe_to_find)

        sorted_similar = get_similar(recipe_index, recipe_to_find, subset_recipe, cosine_sim)

        get_steps(sorted_similar)


# Display the first page if recipe_to_find is empty
#if not recipe_to_find:
#    st.warning('Please enter a recipe name')
#else:
 #   app(recipe_to_find)


if __name__ == '__main__':
    app(recipe_to_find)
