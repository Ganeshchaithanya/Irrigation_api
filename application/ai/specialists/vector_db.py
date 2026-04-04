import chromadb
from chromadb.utils import embedding_functions
import os
import uuid

class VectorDB:
    def __init__(self, persist_directory="./chroma_db"):
        self.persist_directory = persist_directory
        self.client = chromadb.PersistentClient(path=self.persist_directory)
        
        # Use default SentenceTransformer embeddings (No API Key Required for Local Embeddings)
        self.emb_fn = embedding_functions.DefaultEmbeddingFunction()
        
        # Initialize Collections
        self.crop_collection = self.client.get_or_create_collection(
            name="crop_strategies",
            embedding_function=self.emb_fn
        )
        self.exp_collection = self.client.get_or_create_collection(
            name="farm_experience",
            embedding_function=self.emb_fn
        )
        self.expert_collection = self.client.get_or_create_collection(
            name="expert_guides",
            embedding_function=self.emb_fn
        )
        print(f"[RAG] Persistent Collections (Strategies, Experience, Expert) active.")

    def chunk_text(self, text, max_chars=1000):
        """
        Semantic Chunker: 
        Splits long scientific guides into paragraph-sized chunks
        to keep RAG context precise and relevant.
        """
        paragraphs = text.split('\n\n')
        chunks = []
        current_chunk = ""
        for p in paragraphs:
            if len(current_chunk) + len(p) < max_chars:
                current_chunk += p + "\n\n"
            else:
                chunks.append(current_chunk.strip())
                current_chunk = p + "\n\n"
        if current_chunk:
            chunks.append(current_chunk.strip())
        return chunks

    def add_farm_memory(self, event_summary, metadata):
        """Store a semantic summary of a significant farm event."""
        id = f"EXP_{uuid.uuid4()}"
        self.exp_collection.add(
            documents=[event_summary],
            metadatas=[metadata],
            ids=[id]
        )
        print(f"[RAG] Scribed to Farm Memory: {event_summary[:50]}...")
        return True

    def add_crop_knowledge(self, knowledge_list):
        """Ingest researched intelligence into the vector store."""
        documents = []
        metadatas = []
        ids = []
        
        for item in knowledge_list:
            doc_text = f"Crop: {item['crop']} | Soil: {item['soil']} | Market: {item['market']} | Yield: {item.get('yield', 'N/A')}"
            documents.append(doc_text)
            metadatas.append({"soil": item['soil'], "crop": item['crop']})
            ids.append(str(uuid.uuid4()))
            
        if documents:
            self.crop_collection.add(
                documents=documents,
                metadatas=metadatas,
                ids=ids
            )
            print(f"[RAG] Ingested {len(documents)} docs into Chroma.")
        return True

    def retrieve_expert_knowledge(self, query, collection_type="crop", n_results=2, metadata_filter=None):
        """
        Semantic Retrieval with Metadata Filtering:
        Finds relevant agronomic or experience documents using Vector Search.
        """
        if collection_type == "experience":
            collection = self.exp_collection
        elif collection_type == "expert":
            collection = self.expert_collection
        else:
            collection = self.crop_collection
        
        results = collection.query(
            query_texts=[query],
            n_results=n_results,
            where=metadata_filter
        )
        
        # Flatten the results list
        flattened_results = []
        if results and results['documents']:
            for doc_list in results['documents']:
                flattened_results.extend(doc_list)
                
        return flattened_results if flattened_results else ["No specific KB match found."]
