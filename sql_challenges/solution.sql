-- Question that is direct on the file
-- GO TO THE challenge-07 folder to the see the screenshot with the answer
MY_QUESTION = "What is Investment Banking?"
TOP_N = 3

q_emb = model.encode([MY_QUESTION])[0]
q_vec = format_vector(q_emb)

print(f"-- Search query: {MY_QUESTION}")
print(f"-- Top {TOP_N} most similar chunks")
print()
print("SELECT")
print("    chunk_id,")
print("    SUBSTR(chunk_text, 1, 100) AS preview,")
print(f"    ROUND(VECTOR_DISTANCE(chunk_vector, {q_vec}, COSINE), 4) AS similarity_score")
print("FROM doc_chunks")
print("ORDER BY similarity_score ASC")
print(f"FETCH FIRST {TOP_N} ROWS ONLY;")


-- Question that is somehow related
-- GO TO THE challenge-07 folder to the see the screenshot with the answer
MY_QUESTION = "What is a target school?"
TOP_N = 3

q_emb = model.encode([MY_QUESTION])[0]
q_vec = format_vector(q_emb)

print(f"-- Search query: {MY_QUESTION}")
print(f"-- Top {TOP_N} most similar chunks")
print()
print("SELECT")
print("    chunk_id,")
print("    SUBSTR(chunk_text, 1, 100) AS preview,")
print(f"    ROUND(VECTOR_DISTANCE(chunk_vector, {q_vec}, COSINE), 4) AS similarity_score")
print("FROM doc_chunks")
print("ORDER BY similarity_score ASC")
print(f"FETCH FIRST {TOP_N} ROWS ONLY;")

-- Question that has nothing to do
-- GO TO THE challenge-07 folder to the see the screenshot with the answer
MY_QUESTION = "What is your opinion of Fer Jimenez?"
TOP_N = 3

q_emb = model.encode([MY_QUESTION])[0]
q_vec = format_vector(q_emb)

print(f"-- Search query: {MY_QUESTION}")
print(f"-- Top {TOP_N} most similar chunks")
print()
print("SELECT")
print("    chunk_id,")
print("    SUBSTR(chunk_text, 1, 100) AS preview,")
print(f"    ROUND(VECTOR_DISTANCE(chunk_vector, {q_vec}, COSINE), 4) AS similarity_score")
print("FROM doc_chunks")
print("ORDER BY similarity_score ASC")
print(f"FETCH FIRST {TOP_N} ROWS ONLY;")