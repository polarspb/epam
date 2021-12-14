from os import write
import streamlit as st

header = st.container()

with header:
    st.title('Welcome to my app')
    st.text('I am glad to see you on my page')

my_form = st.form(key = "form1")
name = my_form.text_input(label = "Enter the movie title")
submit = my_form.form_submit_button(label = "Submit this form")
if submit:
    st.write('The current movie title is: ', name)

else: 
    st.write('The current movie title is: ')