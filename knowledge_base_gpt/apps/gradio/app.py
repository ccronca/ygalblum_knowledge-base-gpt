#!/bin/env python3

import gradio as gr
from langchain.schema import AIMessage, HumanMessage

from knowledge_base_gpt.libs.gpt.private_chat import PrivateChat

class KnowledgeBaseGradioException(Exception):
    pass


class KnowledgeBaseGradio():
    __instance = None

    @staticmethod
    def get_instance():
        if KnowledgeBaseGradio.__instance is None:
            KnowledgeBaseGradio()
        return KnowledgeBaseGradio.__instance

    def __init__(self):
        if KnowledgeBaseGradio.__instance is not None:
            raise KnowledgeBaseGradioException("This class is a singleton!")
        KnowledgeBaseGradio.__instance = self

    def run(self):
        self._private_chat = PrivateChat()
        with gr.Blocks() as demo:
            chatbot = gr.Chatbot()
            msg = gr.Textbox(label="", autofocus=True)
            clear = gr.ClearButton([msg, chatbot])
            msg.submit(KnowledgeBaseGradio.handle_query, [msg, chatbot], [msg, chatbot])
        demo.launch()

    def _handle_query(self, message, history):
        history_langchain_format = []
        for human, ai in history:
            history_langchain_format.append(HumanMessage(content=human))
            history_langchain_format.append(AIMessage(content=ai))
        answer = self._private_chat.answer_query(history_langchain_format, message)
        history.append((message, answer['answer']))
        return "", history

    @staticmethod
    def handle_query(message, history):
        return KnowledgeBaseGradio.get_instance()._handle_query(message, history)


def main():
    try:
        KnowledgeBaseGradio.get_instance().run()
    except KnowledgeBaseGradioException as e:
        print(e)
        exit(-1)


if __name__ == "__main__":
    main()
