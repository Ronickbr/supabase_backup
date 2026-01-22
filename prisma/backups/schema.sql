


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE TYPE "public"."banner_status" AS ENUM (
    'active',
    'inactive'
);


ALTER TYPE "public"."banner_status" OWNER TO "postgres";


CREATE TYPE "public"."user_role" AS ENUM (
    'admin',
    'editor',
    'viewer'
);


ALTER TYPE "public"."user_role" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_bucket_if_not_exists"("bucket_name" "text", "is_public" boolean DEFAULT true, "file_size_limit" integer DEFAULT 5242880, "allowed_mime_types" "text"[] DEFAULT ARRAY['image/jpeg'::"text", 'image/jpg'::"text", 'image/png'::"text", 'image/gif'::"text", 'image/svg+xml'::"text", 'image/webp'::"text"]) RETURNS "void"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
  -- Verificar se o bucket já existe
  IF NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id = bucket_name) THEN
    -- Criar o bucket
    INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
    VALUES (bucket_name, bucket_name, is_public, file_size_limit, allowed_mime_types);
    
    RAISE NOTICE 'Bucket % criado com sucesso', bucket_name;
  ELSE
    RAISE NOTICE 'Bucket % já existe', bucket_name;
  END IF;
END;
$$;


ALTER FUNCTION "public"."create_bucket_if_not_exists"("bucket_name" "text", "is_public" boolean, "file_size_limit" integer, "allowed_mime_types" "text"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_admin"() RETURNS boolean
    LANGUAGE "sql" STABLE
    SET "search_path" TO ''
    AS $$
select coalesce((current_setting('request.jwt.claims', true)::jsonb -> 'user_metadata' ->> 'role') in ('admin','super_admin'), false);
$$;


ALTER FUNCTION "public"."is_admin"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_super_admin"() RETURNS boolean
    LANGUAGE "sql" STABLE
    SET "search_path" TO ''
    AS $$
select coalesce((current_setting('request.jwt.claims', true)::jsonb -> 'user_metadata' ->> 'role') = 'super_admin', false);
$$;


ALTER FUNCTION "public"."is_super_admin"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."touch_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO '$user', 'public', 'extensions'
    AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."touch_updated_at"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."activity_logs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "action" character varying(50) NOT NULL,
    "resource_type" character varying(50) NOT NULL,
    "resource_id" character varying(100),
    "details" "jsonb",
    "ip_address" "inet",
    "user_agent" "text",
    "status" character varying(20) DEFAULT 'success'::character varying,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."activity_logs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."admin_users" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "email" character varying(255) NOT NULL,
    "password_hash" character varying(255) NOT NULL,
    "name" character varying(255) NOT NULL,
    "role" character varying(50) DEFAULT 'admin'::character varying,
    "active" boolean DEFAULT true,
    "created_at" timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "admin_users_role_check" CHECK ((("role")::"text" = ANY ((ARRAY['admin'::character varying, 'super_admin'::character varying])::"text"[])))
);


ALTER TABLE "public"."admin_users" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."banners" (
    "id" integer NOT NULL,
    "title" character varying(255) NOT NULL,
    "description" "text",
    "image_url" character varying(1024),
    "link_url" character varying(255),
    "start_date" "date",
    "end_date" "date",
    "clicks" integer DEFAULT 0,
    "impressions" integer DEFAULT 0,
    "created_at" timestamp(6) without time zone,
    "updated_at" timestamp(6) without time zone,
    "sort_order" integer DEFAULT 0,
    "active" boolean DEFAULT true NOT NULL
);


ALTER TABLE "public"."banners" OWNER TO "postgres";


ALTER TABLE "public"."banners" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."banners_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."brands" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" character varying(255) NOT NULL,
    "slug" character varying(255) NOT NULL,
    "logo_url" "text",
    "created_at" timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."brands" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."categories" (
    "id" integer NOT NULL,
    "name" character varying(255) NOT NULL,
    "slug" character varying(255) NOT NULL,
    "active" boolean DEFAULT true NOT NULL,
    "featured_product_id" integer,
    "created_at" timestamp(6) without time zone,
    "updated_at" timestamp(6) without time zone,
    "sort_order" integer DEFAULT 0,
    "parent_id" integer,
    "is_active" boolean DEFAULT true NOT NULL
);


ALTER TABLE "public"."categories" OWNER TO "postgres";


COMMENT ON TABLE "public"."categories" IS 'Tabela unificada de categorias e subcategorias com estrutura hierárquica';



COMMENT ON COLUMN "public"."categories"."parent_id" IS 'ID da categoria pai. NULL para categorias principais, preenchido para subcategorias';



COMMENT ON COLUMN "public"."categories"."is_active" IS 'Indica se a categoria está ativa';



ALTER TABLE "public"."categories" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."categories_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."leads" (
    "id" integer NOT NULL,
    "name" character varying(255) NOT NULL,
    "email" character varying(255) NOT NULL,
    "phone" character varying(50),
    "message" "text",
    "status" character varying(50) DEFAULT 'new'::character varying,
    "created_at" timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."leads" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."leads_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."leads_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."leads_id_seq" OWNED BY "public"."leads"."id";



CREATE TABLE IF NOT EXISTS "public"."product_images" (
    "id" integer NOT NULL,
    "product_id" integer NOT NULL,
    "url" character varying(1024) NOT NULL,
    "sort_order" integer DEFAULT 0,
    "created_at" timestamp(6) without time zone
);


ALTER TABLE "public"."product_images" OWNER TO "postgres";


ALTER TABLE "public"."product_images" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."product_images_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."products" (
    "id" integer NOT NULL,
    "name" character varying(255) NOT NULL,
    "slug" character varying(255) NOT NULL,
    "description" "text",
    "category_id" integer NOT NULL,
    "subcategory_id" integer,
    "brand" character varying(255),
    "image" character varying(1024),
    "specifications" "text",
    "seo_title" character varying(255),
    "seo_description" "text",
    "seo_keywords" character varying(255),
    "featured" boolean DEFAULT false NOT NULL,
    "active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp(6) without time zone,
    "updated_at" timestamp(6) without time zone,
    "featured_on_homepage" boolean DEFAULT false,
    "featured_in_dropdown" boolean DEFAULT false,
    "is_disabled" boolean DEFAULT false,
    "price" numeric(10,2)
);


ALTER TABLE "public"."products" OWNER TO "postgres";


ALTER TABLE "public"."products" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."products_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."promotion_products" (
    "promotion_id" integer NOT NULL,
    "product_id" integer NOT NULL
);


ALTER TABLE "public"."promotion_products" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."promotions" (
    "id" integer NOT NULL,
    "title" character varying(255) NOT NULL,
    "description" "text",
    "discount_percentage" numeric(5,2) NOT NULL,
    "start_date" "date",
    "end_date" "date",
    "active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp(6) without time zone,
    "updated_at" timestamp(6) without time zone,
    "image_url" "text",
    "link_url" "text",
    "trigger_type" "text",
    "trigger_value" numeric,
    "template_type" "text",
    "content_layout" "jsonb",
    CONSTRAINT "promotions_template_type_check" CHECK (("template_type" = ANY (ARRAY['first_purchase'::"text", 'abandoned_cart'::"text", 'exit_intent'::"text", 'special_date'::"text", 'custom'::"text"]))),
    CONSTRAINT "promotions_trigger_type_check" CHECK (("trigger_type" = ANY (ARRAY['exit_intent'::"text", 'time'::"text", 'scroll'::"text", 'inactivity'::"text"])))
);


ALTER TABLE "public"."promotions" OWNER TO "postgres";


ALTER TABLE "public"."promotions" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."promotions_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."site_settings" (
    "id" integer NOT NULL,
    "site_info" "jsonb",
    "integrations" "jsonb",
    "maintenance" "jsonb",
    "theme" "jsonb",
    "contact" "jsonb",
    "social_media" "jsonb",
    "seo" "jsonb",
    "created_at" timestamp(6) without time zone,
    "updated_at" timestamp(6) without time zone
);


ALTER TABLE "public"."site_settings" OWNER TO "postgres";


ALTER TABLE "public"."site_settings" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."site_settings_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."stores" (
    "id" integer NOT NULL,
    "name" character varying(255) NOT NULL,
    "whatsapp_number" character varying(30),
    "email" character varying(255),
    "phone" character varying(20),
    "address" character varying(512),
    "active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp(6) without time zone,
    "updated_at" timestamp(6) without time zone
);


ALTER TABLE "public"."stores" OWNER TO "postgres";


ALTER TABLE "public"."stores" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."stores_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."users" (
    "id" "uuid" NOT NULL,
    "name" character varying(255) NOT NULL,
    "email" character varying(255) NOT NULL,
    "phone" character varying(20),
    "role" character varying(50),
    "is_active" boolean DEFAULT true NOT NULL,
    "avatar" "text",
    "created_at" timestamp(6) without time zone,
    "last_login" timestamp(6) without time zone
);


ALTER TABLE "public"."users" OWNER TO "postgres";


ALTER TABLE ONLY "public"."leads" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."leads_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."activity_logs"
    ADD CONSTRAINT "activity_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."admin_users"
    ADD CONSTRAINT "admin_users_email_key" UNIQUE ("email");



ALTER TABLE ONLY "public"."admin_users"
    ADD CONSTRAINT "admin_users_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."banners"
    ADD CONSTRAINT "banners_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."brands"
    ADD CONSTRAINT "brands_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."brands"
    ADD CONSTRAINT "brands_slug_key" UNIQUE ("slug");



ALTER TABLE ONLY "public"."categories"
    ADD CONSTRAINT "categories_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."leads"
    ADD CONSTRAINT "leads_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."product_images"
    ADD CONSTRAINT "product_images_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."products"
    ADD CONSTRAINT "products_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."promotion_products"
    ADD CONSTRAINT "promotion_products_pkey" PRIMARY KEY ("promotion_id", "product_id");



ALTER TABLE ONLY "public"."promotions"
    ADD CONSTRAINT "promotions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."site_settings"
    ADD CONSTRAINT "site_settings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."stores"
    ADD CONSTRAINT "stores_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."categories"
    ADD CONSTRAINT "uq_categories_slug" UNIQUE ("slug");



ALTER TABLE ONLY "public"."products"
    ADD CONSTRAINT "uq_products_slug" UNIQUE ("slug");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "uq_users_email" UNIQUE ("email");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_pkey" PRIMARY KEY ("id");



CREATE INDEX "idx_activity_logs_user_id" ON "public"."activity_logs" USING "btree" ("user_id");



CREATE INDEX "idx_admin_users_active" ON "public"."admin_users" USING "btree" ("active");



CREATE INDEX "idx_admin_users_email" ON "public"."admin_users" USING "btree" ("email");



CREATE INDEX "idx_brands_name" ON "public"."brands" USING "btree" ("name");



CREATE INDEX "idx_brands_slug" ON "public"."brands" USING "btree" ("slug");



CREATE INDEX "idx_categories_parent_id" ON "public"."categories" USING "btree" ("parent_id");



CREATE INDEX "idx_featured_product_id" ON "public"."categories" USING "btree" ("featured_product_id");



CREATE INDEX "idx_leads_created_at" ON "public"."leads" USING "btree" ("created_at");



CREATE INDEX "idx_leads_email" ON "public"."leads" USING "btree" ("email");



CREATE INDEX "idx_leads_status" ON "public"."leads" USING "btree" ("status");



CREATE INDEX "idx_product_images_product_id" ON "public"."product_images" USING "btree" ("product_id");



CREATE INDEX "idx_products_category_id" ON "public"."products" USING "btree" ("category_id");



CREATE INDEX "idx_products_subcategory_id" ON "public"."products" USING "btree" ("subcategory_id");



CREATE INDEX "idx_promotion_products_product_id" ON "public"."promotion_products" USING "btree" ("product_id");



CREATE INDEX "idx_promotion_products_promotion_id" ON "public"."promotion_products" USING "btree" ("promotion_id");



ALTER TABLE ONLY "public"."activity_logs"
    ADD CONSTRAINT "activity_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."categories"
    ADD CONSTRAINT "fk_categories_parent" FOREIGN KEY ("parent_id") REFERENCES "public"."categories"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."product_images"
    ADD CONSTRAINT "fk_product_images_product" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."products"
    ADD CONSTRAINT "fk_products_category" FOREIGN KEY ("category_id") REFERENCES "public"."categories"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."promotion_products"
    ADD CONSTRAINT "fk_promotion_products_product" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."promotion_products"
    ADD CONSTRAINT "fk_promotion_products_promotion" FOREIGN KEY ("promotion_id") REFERENCES "public"."promotions"("id") ON UPDATE CASCADE ON DELETE CASCADE;



CREATE POLICY "Admin Delete Access on users" ON "public"."users" FOR DELETE USING ((("auth"."jwt"() ->> 'is_admin'::"text") = 'true'::"text"));



CREATE POLICY "Admin Insert Access on users" ON "public"."users" FOR INSERT WITH CHECK ((("auth"."jwt"() ->> 'is_admin'::"text") = 'true'::"text"));



CREATE POLICY "Admin Update Access on users" ON "public"."users" FOR UPDATE USING ((("auth"."jwt"() ->> 'is_admin'::"text") = 'true'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'is_admin'::"text") = 'true'::"text"));



CREATE POLICY "Admin Write Access on admin_users" ON "public"."admin_users" USING ((("auth"."jwt"() ->> 'is_admin'::"text") = 'true'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'is_admin'::"text") = 'true'::"text"));



CREATE POLICY "Admin Write Access on promotion_products" ON "public"."promotion_products" USING ((("auth"."jwt"() ->> 'is_admin'::"text") = 'true'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'is_admin'::"text") = 'true'::"text"));



CREATE POLICY "Admin Write Access on site_settings" ON "public"."site_settings" USING ((("auth"."jwt"() ->> 'is_admin'::"text") = 'true'::"text")) WITH CHECK ((("auth"."jwt"() ->> 'is_admin'::"text") = 'true'::"text"));



CREATE POLICY "Admin Write Access on stores" ON "public"."stores" TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Admin users can view all activity logs" ON "public"."activity_logs" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."admin_users"
  WHERE (("admin_users"."id" = "auth"."uid"()) AND (("admin_users"."role")::"text" = ANY ((ARRAY['admin'::character varying, 'super_admin'::character varying])::"text"[]))))));



CREATE POLICY "Admins can perform all actions" ON "public"."admin_users" USING (("auth"."role"() = 'admin'::"text"));



CREATE POLICY "Anyone can view active categories" ON "public"."categories" FOR SELECT USING (("active" = true));



CREATE POLICY "Authenticated users can delete leads" ON "public"."leads" FOR DELETE USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Authenticated users can insert activity logs" ON "public"."activity_logs" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Authenticated users can manage categories" ON "public"."categories" USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Authenticated users can update leads" ON "public"."leads" FOR UPDATE USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Authenticated users can view all categories" ON "public"."categories" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Authenticated users can view leads" ON "public"."leads" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Gestão por admins" ON "public"."promotions" TO "authenticated" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "Leitura pública" ON "public"."promotions" FOR SELECT USING (true);



CREATE POLICY "Leitura pública de banners ativos" ON "public"."banners" FOR SELECT USING (("active" = true));



CREATE POLICY "Leitura pública de imagens de produto" ON "public"."product_images" FOR SELECT USING (true);



CREATE POLICY "Leitura pública de marcas" ON "public"."brands" FOR SELECT USING (true);



CREATE POLICY "Leitura pública de produtos ativos" ON "public"."products" FOR SELECT USING ((("active" = true) AND (("is_disabled" IS NULL) OR ("is_disabled" = false))));



CREATE POLICY "Permitir atualização de leads para usuários autenticados" ON "public"."leads" FOR UPDATE USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Permitir exclusão de leads para usuários autenticados" ON "public"."leads" FOR DELETE USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Permitir leitura de categorias ativas" ON "public"."categories" FOR SELECT USING (("active" = true));



CREATE POLICY "Permitir leitura de leads para todos" ON "public"."leads" FOR SELECT USING (true);



CREATE POLICY "Public Read Access on admin_users" ON "public"."admin_users" FOR SELECT USING (true);



CREATE POLICY "Public Read Access on promotion_products" ON "public"."promotion_products" FOR SELECT USING (true);



CREATE POLICY "Public Read Access on site_settings" ON "public"."site_settings" FOR SELECT USING (true);



CREATE POLICY "Public Read Access on stores" ON "public"."stores" FOR SELECT USING (true);



CREATE POLICY "Public Read Access on users" ON "public"."users" FOR SELECT USING (true);



CREATE POLICY "Users can view their own activity logs" ON "public"."activity_logs" FOR SELECT USING (("auth"."uid"() = "user_id"));



ALTER TABLE "public"."activity_logs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."admin_users" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "anon_insert_activity_logs" ON "public"."activity_logs" FOR INSERT TO "anon" WITH CHECK (((("action")::"text" = ANY ((ARRAY['product_view'::character varying, 'site_visit'::character varying, 'whatsapp_click'::character varying])::"text"[])) AND (("resource_type")::"text" = ANY ((ARRAY['product'::character varying, 'site'::character varying, 'store'::character varying])::"text"[])) AND ((COALESCE("resource_id", ''::character varying))::"text" <> ''::"text")));



CREATE POLICY "anon_insert_leads" ON "public"."leads" FOR INSERT TO "anon" WITH CHECK ((((COALESCE("name", ''::character varying))::"text" <> ''::"text") AND (((COALESCE("email", ''::character varying))::"text" <> ''::"text") OR ((COALESCE("phone", ''::character varying))::"text" <> ''::"text"))));



CREATE POLICY "anon_select_activity_logs" ON "public"."activity_logs" FOR SELECT TO "anon" USING (true);



CREATE POLICY "anon_select_categories" ON "public"."categories" FOR SELECT TO "anon" USING (("active" = true));



CREATE POLICY "anon_select_product_images" ON "public"."product_images" FOR SELECT TO "anon" USING (true);



CREATE POLICY "anon_select_products" ON "public"."products" FOR SELECT TO "anon" USING (("active" = true));



CREATE POLICY "anon_select_site_settings" ON "public"."site_settings" FOR SELECT TO "anon" USING (true);



CREATE POLICY "anon_select_stores" ON "public"."stores" FOR SELECT TO "anon" USING (true);



ALTER TABLE "public"."banners" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "banners_write_admin" ON "public"."banners" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



ALTER TABLE "public"."brands" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "brands_write_admin" ON "public"."brands" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



ALTER TABLE "public"."categories" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."leads" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "leads_insert_public" ON "public"."leads" FOR INSERT WITH CHECK (true);



ALTER TABLE "public"."product_images" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "product_images_delete_admin" ON "public"."product_images" FOR DELETE USING ("public"."is_admin"());



CREATE POLICY "product_images_select_all" ON "public"."product_images" FOR SELECT USING (true);



CREATE POLICY "product_images_update_admin" ON "public"."product_images" FOR UPDATE USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "product_images_write_admin" ON "public"."product_images" FOR INSERT WITH CHECK ("public"."is_admin"());



ALTER TABLE "public"."products" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "products_delete_admin" ON "public"."products" FOR DELETE USING ("public"."is_admin"());



CREATE POLICY "products_select_all" ON "public"."products" FOR SELECT USING (true);



CREATE POLICY "products_update_admin" ON "public"."products" FOR UPDATE USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "products_write_admin" ON "public"."products" FOR INSERT WITH CHECK ("public"."is_admin"());



ALTER TABLE "public"."promotion_products" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."promotions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."site_settings" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "site_settings_select_all" ON "public"."site_settings" FOR SELECT USING (true);



CREATE POLICY "site_settings_update_admin" ON "public"."site_settings" FOR UPDATE USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "site_settings_write_admin" ON "public"."site_settings" FOR INSERT WITH CHECK ("public"."is_admin"());



ALTER TABLE "public"."stores" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."users" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";






GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

























































































































































GRANT ALL ON FUNCTION "public"."create_bucket_if_not_exists"("bucket_name" "text", "is_public" boolean, "file_size_limit" integer, "allowed_mime_types" "text"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."create_bucket_if_not_exists"("bucket_name" "text", "is_public" boolean, "file_size_limit" integer, "allowed_mime_types" "text"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_bucket_if_not_exists"("bucket_name" "text", "is_public" boolean, "file_size_limit" integer, "allowed_mime_types" "text"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."is_admin"() TO "anon";
GRANT ALL ON FUNCTION "public"."is_admin"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_admin"() TO "service_role";



GRANT ALL ON FUNCTION "public"."is_super_admin"() TO "anon";
GRANT ALL ON FUNCTION "public"."is_super_admin"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_super_admin"() TO "service_role";



GRANT ALL ON FUNCTION "public"."touch_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."touch_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."touch_updated_at"() TO "service_role";


















GRANT ALL ON TABLE "public"."activity_logs" TO "anon";
GRANT ALL ON TABLE "public"."activity_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."activity_logs" TO "service_role";



GRANT ALL ON TABLE "public"."admin_users" TO "anon";
GRANT ALL ON TABLE "public"."admin_users" TO "authenticated";
GRANT ALL ON TABLE "public"."admin_users" TO "service_role";



GRANT ALL ON TABLE "public"."banners" TO "anon";
GRANT ALL ON TABLE "public"."banners" TO "authenticated";
GRANT ALL ON TABLE "public"."banners" TO "service_role";



GRANT ALL ON SEQUENCE "public"."banners_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."banners_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."banners_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."brands" TO "anon";
GRANT ALL ON TABLE "public"."brands" TO "authenticated";
GRANT ALL ON TABLE "public"."brands" TO "service_role";



GRANT ALL ON TABLE "public"."categories" TO "anon";
GRANT ALL ON TABLE "public"."categories" TO "authenticated";
GRANT ALL ON TABLE "public"."categories" TO "service_role";



GRANT ALL ON SEQUENCE "public"."categories_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."categories_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."categories_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."leads" TO "anon";
GRANT ALL ON TABLE "public"."leads" TO "authenticated";
GRANT ALL ON TABLE "public"."leads" TO "service_role";



GRANT ALL ON SEQUENCE "public"."leads_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."leads_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."leads_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."product_images" TO "anon";
GRANT ALL ON TABLE "public"."product_images" TO "authenticated";
GRANT ALL ON TABLE "public"."product_images" TO "service_role";



GRANT ALL ON SEQUENCE "public"."product_images_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."product_images_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."product_images_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."products" TO "anon";
GRANT ALL ON TABLE "public"."products" TO "authenticated";
GRANT ALL ON TABLE "public"."products" TO "service_role";



GRANT ALL ON SEQUENCE "public"."products_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."products_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."products_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."promotion_products" TO "anon";
GRANT ALL ON TABLE "public"."promotion_products" TO "authenticated";
GRANT ALL ON TABLE "public"."promotion_products" TO "service_role";



GRANT ALL ON TABLE "public"."promotions" TO "anon";
GRANT ALL ON TABLE "public"."promotions" TO "authenticated";
GRANT ALL ON TABLE "public"."promotions" TO "service_role";



GRANT ALL ON SEQUENCE "public"."promotions_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."promotions_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."promotions_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."site_settings" TO "anon";
GRANT ALL ON TABLE "public"."site_settings" TO "authenticated";
GRANT ALL ON TABLE "public"."site_settings" TO "service_role";



GRANT ALL ON SEQUENCE "public"."site_settings_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."site_settings_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."site_settings_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."stores" TO "anon";
GRANT ALL ON TABLE "public"."stores" TO "authenticated";
GRANT ALL ON TABLE "public"."stores" TO "service_role";



GRANT ALL ON SEQUENCE "public"."stores_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."stores_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."stores_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."users" TO "anon";
GRANT ALL ON TABLE "public"."users" TO "authenticated";
GRANT ALL ON TABLE "public"."users" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";































